# Karpenter Helm Install (manual step or automate with Terraform Helm provider)

# Option 1: Manual Helm Install (recommended for first-time setup)
# See official docs: https://karpenter.sh/v1.8.1/getting-started/

# Option 2: Terraform Helm Provider Example
# Uncomment and adjust if you want to automate with Terraform
# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   repository = "oci://public.ecr.aws/karpenter/karpenter"
#   chart      = "karpenter"
#   version    = "1.8.1"
#   namespace  = "kube-system"
#   create_namespace = true
#   set {
#     name  = "settings.clusterName"
#     value = var.cluster_name
#   }
#   set {
#     name  = "settings.interruptionQueue"
#     value = "${var.cluster_name}-karpenter"
#   }
#   set {
#     name  = "settings.defaultInstanceProfile"
#     value = "KarpenterNodeRole-${var.cluster_name}"
#   }
#   set {
#     name  = "settings.clusterEndpoint"
#     value = var.cluster_endpoint
#   }
#   set {
#     name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
#     value = module.iam.karpenter_node_role_arn
#   }
#   depends_on = [module.iam, module.karpenter]
# }
