#!/bin/bash

# Kubernetes Pod Diagnostics Script
# This script diagnoses why pods are stuck in Init, Pending, or error states

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubernetes Pod Diagnostics Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Get all namespaces with failing pods
NAMESPACES=$(kubectl get pods -A | grep -E '(Pending|Init:|Error|CrashLoop|ImagePull)' | awk '{print $1}' | sort -u)

if [ -z "$NAMESPACES" ]; then
    echo -e "${GREEN}No problematic pods found!${NC}"
    exit 0
fi

echo -e "${YELLOW}Found issues in namespaces: ${NAMESPACES}${NC}\n"

# Function to check node resources
check_node_resources() {
    echo -e "\n${BLUE}=== Node Resources ===${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    
    echo -e "\n${BLUE}=== Node Capacity ===${NC}"
    kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-CAPACITY:.status.capacity.cpu,MEMORY-CAPACITY:.status.capacity.memory,CPU-ALLOCATABLE:.status.allocatable.cpu,MEMORY-ALLOCATABLE:.status.allocatable.memory
}

# Function to check pod events
check_pod_events() {
    local namespace=$1
    local pod=$2
    
    echo -e "\n${RED}--- Events for $pod ---${NC}"
    kubectl get events -n "$namespace" --field-selector involvedObject.name="$pod" --sort-by='.lastTimestamp' | tail -10
}

# Function to check pod description
check_pod_details() {
    local namespace=$1
    local pod=$2
    
    echo -e "\n${YELLOW}--- Pod Description for $pod ---${NC}"
    kubectl describe pod -n "$namespace" "$pod" | grep -A 20 "Conditions:\|Events:"
}

# Function to check init container logs
check_init_logs() {
    local namespace=$1
    local pod=$2
    
    echo -e "\n${YELLOW}--- Init Container Status for $pod ---${NC}"
    kubectl get pod -n "$namespace" "$pod" -o jsonpath='{range .status.initContainerStatuses[*]}{.name}{"\t"}{.state}{"\n"}{end}'
    
    echo -e "\n${YELLOW}--- Init Container Logs ---${NC}"
    local init_containers=$(kubectl get pod -n "$namespace" "$pod" -o jsonpath='{.spec.initContainers[*].name}')
    for container in $init_containers; do
        echo -e "\n${BLUE}Init Container: $container${NC}"
        kubectl logs -n "$namespace" "$pod" -c "$container" --tail=20 2>&1 || echo "No logs available yet"
    done
}

# Function to check image pull secrets
check_image_secrets() {
    local namespace=$1
    
    echo -e "\n${BLUE}=== Image Pull Secrets in $namespace ===${NC}"
    kubectl get secrets -n "$namespace" | grep docker-registry || echo "No docker registry secrets found"
    
    echo -e "\n${BLUE}=== Service Account Image Pull Secrets ===${NC}"
    kubectl get sa -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.imagePullSecrets[*].name}{"\n"}{end}'
}

# Function to check PVC status
check_pvc_status() {
    local namespace=$1
    
    echo -e "\n${BLUE}=== PVC Status in $namespace ===${NC}"
    kubectl get pvc -n "$namespace" 2>/dev/null || echo "No PVCs in namespace"
}

# Function to check resource quotas
check_quotas() {
    local namespace=$1
    
    echo -e "\n${BLUE}=== Resource Quotas in $namespace ===${NC}"
    kubectl get resourcequota -n "$namespace" 2>/dev/null || echo "No resource quotas"
    kubectl describe resourcequota -n "$namespace" 2>/dev/null
}

# Main diagnostics loop
for ns in $NAMESPACES; do
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Namespace: $ns${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # Get problematic pods in this namespace
    PODS=$(kubectl get pods -n "$ns" | grep -E '(Pending|Init:|Error|CrashLoop|ImagePull)' | awk '{print $1}')
    
    echo -e "\n${YELLOW}Problematic pods:${NC}"
    kubectl get pods -n "$ns" | grep -E '(Pending|Init:|Error|CrashLoop|ImagePull)' | head -20
    
    # Check namespace-level issues
    check_image_secrets "$ns"
    check_pvc_status "$ns"
    check_quotas "$ns"
    
    # Check individual pods
    for pod in $PODS; do
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}Diagnosing: $pod${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Get pod status
        STATUS=$(kubectl get pod -n "$ns" "$pod" -o jsonpath='{.status.phase}')
        REASON=$(kubectl get pod -n "$ns" "$pod" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo "N/A")
        
        echo -e "Status: ${YELLOW}$STATUS${NC}"
        echo -e "Reason: ${YELLOW}$REASON${NC}"
        
        # Check events
        check_pod_events "$ns" "$pod"
        
        # If in Init state, check init containers
        if kubectl get pod -n "$ns" "$pod" -o jsonpath='{.status.phase}' | grep -q "Pending\|Running"; then
            INIT_STATUS=$(kubectl get pod -n "$ns" "$pod" -o jsonpath='{.status.initContainerStatuses[*].state}')
            if [ ! -z "$INIT_STATUS" ]; then
                check_init_logs "$ns" "$pod"
            fi
        fi
        
        # Check pod details
        check_pod_details "$ns" "$pod"
        
        # Check for specific issues
        echo -e "\n${YELLOW}--- Checking Common Issues ---${NC}"
        
        # Image pull issues
        if echo "$REASON" | grep -iq "image"; then
            echo -e "${RED}⚠ Image Pull Issue Detected${NC}"
            kubectl get pod -n "$ns" "$pod" -o jsonpath='{.spec.containers[*].image}{"\n"}'
            kubectl get pod -n "$ns" "$pod" -o jsonpath='{.spec.imagePullSecrets[*].name}{"\n"}'
        fi
        
        # Resource issues
        if [ "$STATUS" == "Pending" ]; then
            echo -e "${RED}⚠ Pod is Pending - Checking Resources${NC}"
            kubectl get pod -n "$ns" "$pod" -o jsonpath='{.spec.containers[*].resources}{"\n"}'
        fi
        
        echo -e "\n"
    done
done

# Check cluster-wide resources
check_node_resources

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Diagnostic Summary${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Common Issues to Check:${NC}"
echo -e "1. ${BLUE}Image Pull Errors${NC}: Check ECR secrets, image names, and registry access"
echo -e "2. ${BLUE}Pending Pods${NC}: Check node resources (CPU/Memory), PVC binding, node selectors"
echo -e "3. ${BLUE}Init Container Failures${NC}: Check init container logs and configurations"
echo -e "4. ${BLUE}Resource Limits${NC}: Check if resource quotas or limits are exceeded"
echo -e "5. ${BLUE}Network Issues${NC}: Check if pods can reach required services"

echo -e "\n${YELLOW}Suggested Commands:${NC}"
echo -e "- ${BLUE}kubectl describe pod -n <namespace> <pod-name>${NC}"
echo -e "- ${BLUE}kubectl logs -n <namespace> <pod-name> -c <init-container>${NC}"
echo -e "- ${BLUE}kubectl get events -n <namespace> --sort-by='.lastTimestamp'${NC}"
echo -e "- ${BLUE}kubectl top nodes${NC}"
echo -e "- ${BLUE}kubectl get pvc -A${NC}"

echo -e "\n${GREEN}Diagnostics complete!${NC}\n"
