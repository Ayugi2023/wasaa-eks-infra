#!/bin/bash

# WASAA Platform ArgoCD Deployment Script
# This script installs ArgoCD and deploys the complete WASAA platform
#
# Usage:
#   Interactive mode: ./deploy-wasaa.sh
#   Command line mode: ./deploy-wasaa.sh <github_username> <github_token> <environment>
#
# Arguments (for command line mode):
#   github_username: Your GitHub username
#   github_token:    Your GitHub Personal Access Token
#   environment:     Environment to deploy (developer|staging|production)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}

    print_info "Waiting for deployment $deployment in namespace $namespace to be ready..."
    if kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace >/dev/null 2>&1; then
        print_success "Deployment $deployment is ready"
    else
        print_error "Deployment $deployment failed to become ready within $timeout seconds"
        return 1
    fi
}

# Function to check if ArgoCD is installed
check_argocd_installed() {
    if kubectl get namespace argocd >/dev/null 2>&1; then
        print_info "ArgoCD namespace exists"
        if kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
            print_success "ArgoCD is already installed"
            return 0
        fi
    fi
    return 1
}

# Function to install ArgoCD
install_argocd() {
    print_info "Installing ArgoCD..."

    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Wait for ArgoCD to be ready
    wait_for_deployment argocd argocd-server

    print_success "ArgoCD installed successfully"
}

# Function to get ArgoCD admin password
get_argocd_password() {
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
}

# Function to install ArgoCD CLI
install_argocd_cli() {
    if command_exists argocd; then
        print_info "ArgoCD CLI is already installed"
        return 0
    fi

    print_info "Installing ArgoCD CLI..."

    # Detect OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Download and install CLI
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-$OS-$ARCH
    chmod +x argocd
    sudo mv argocd /usr/local/bin/

    print_success "ArgoCD CLI installed"
}

# Function to add repositories to ArgoCD
add_repositories() {
    local username=$1
    local token=$2

    print_info "Adding repositories to ArgoCD..."

    # Login to ArgoCD
    local password=$(get_argocd_password)
    argocd login localhost:8080 --username admin --password "$password" --insecure

    # Add wasaa-infra repository
    print_info "Adding wasaa-infra repository..."
    argocd repo add https://github.com/web-masters-ke/wasaa-infra \
        --username "$username" \
        --password "$token" \
        --name wasaa-infra \
        --upsert

    # Add wasaa-helm-charts repository
    print_info "Adding wasaa-helm-charts repository..."
    argocd repo add https://github.com/web-masters-ke/wasaa-chat-helm-charts \
        --username "$username" \
        --password "$token" \
        --name wasaa-helm-charts \
        --upsert

    print_success "Repositories added successfully"
}

# Function to create ArgoCD project
create_project() {
    print_info "Creating WASAA applications project..."
    kubectl apply -f projects/wasaa-applications.yaml
    print_success "Project created successfully"
}

# Function to deploy root application
deploy_root_app() {
    local environment=$1

    print_info "Deploying $environment environment root application..."

    case $environment in
        developer)
            kubectl apply -f developer-root.yaml
            ;;
        staging)
            kubectl apply -f staging-root.yaml
            ;;
        production)
            kubectl apply -f production-root.yaml
            ;;
        *)
            print_error "Invalid environment: $environment. Must be developer, staging, or production"
            exit 1
            ;;
    esac

    print_success "$environment environment deployed successfully"
}

# Function to show deployment status
show_status() {
    print_info "Current ArgoCD applications status:"
    echo ""

    # Port forward ArgoCD server for UI access
    print_info "To access ArgoCD UI:"
    print_info "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
    print_info "  URL: https://localhost:8080"
    print_info "  Username: admin"
    print_info "  Password: $(get_argocd_password)"
    echo ""

    print_info "To check application status:"
    print_info "  argocd app list"
    print_info "  argocd app get wasaa-$1-root"
    echo ""

    print_info "To check pod status:"
    print_info "  kubectl get pods -A | grep -E '(wasaa|monitoring|ingress)'"
}

# Main function
main() {
    local github_username=""
    local github_token=""
    local environment=""

    # Check if arguments are provided via command line
    if [ $# -eq 3 ]; then
        github_username=$1
        github_token=$2
        environment=$3
    else
        # Interactive prompts
        echo ""
        print_info "WASAA Platform ArgoCD Deployment Script"
        echo "========================================"
        echo ""

        # Prompt for GitHub username
        while [ -z "$github_username" ]; do
            read -p "Enter your GitHub username: " github_username
            if [ -z "$github_username" ]; then
                print_warning "GitHub username cannot be empty. Please try again."
            fi
        done

        # Prompt for GitHub token
        while [ -z "$github_token" ]; do
            read -s -p "Enter your GitHub Personal Access Token: " github_token
            echo ""  # New line after hidden input
            if [ -z "$github_token" ]; then
                print_warning "GitHub token cannot be empty. Please try again."
            fi
        done

        # Prompt for environment
        while [[ ! "$environment" =~ ^(developer|staging|production)$ ]]; do
            read -p "Enter environment to deploy (developer/staging/production): " environment
            if [[ ! "$environment" =~ ^(developer|staging|production)$ ]]; then
                print_warning "Invalid environment. Please choose: developer, staging, or production"
            fi
        done
    fi

    print_info "Starting WASAA Platform deployment..."
    print_info "Environment: $environment"
    print_info "GitHub User: $github_username"
    echo ""

    # Check prerequisites
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "kubectl is not configured to access a Kubernetes cluster."
        exit 1
    fi

    # Install ArgoCD CLI
    install_argocd_cli

    # Check if ArgoCD is already installed
    if ! check_argocd_installed; then
        install_argocd
    else
        print_info "ArgoCD is already installed, skipping installation"
    fi

    # Port forward ArgoCD server for CLI access
    print_info "Setting up port forwarding for ArgoCD CLI access..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
    PORT_FORWARD_PID=$!

    # Wait a moment for port forwarding to establish
    sleep 3

    # Add repositories
    add_repositories "$github_username" "$github_token"

    # Create project
    create_project

    # Deploy root application
    deploy_root_app "$environment"

    # Kill port forwarding
    kill $PORT_FORWARD_PID 2>/dev/null || true

    print_success "WASAA Platform deployment initiated!"
    echo ""

    # Show status and next steps
    show_status "$environment"

    print_info "The deployment will take several minutes to complete."
    print_info "Monitor progress in the ArgoCD UI or using the commands above."
}

# Run main function with all arguments
main "$@"