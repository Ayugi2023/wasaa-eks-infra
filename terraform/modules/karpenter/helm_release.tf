resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.8.1"  # Use latest stable version
  namespace        = "kube-system"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      settings = {
        clusterName       = var.cluster_name
        interruptionQueue = "${var.cluster_name}"
      }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
        }
      }
      controller = {
        resources = {
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
            extraVolumes = [
              {
                name: "aws-iam-token"
                projected: {
                  sources: [
                    {
                      serviceAccountToken: {
                        path: "token"
                        audience: "sts.amazonaws.com"
                        expirationSeconds: 86400
                      }
                    }
                  ]
                }
              }
            ]
            extraVolumeMounts = [
              {
                name: "aws-iam-token"
                mountPath: "/var/run/secrets/eks.amazonaws.com/serviceaccount"
                readOnly: true
              }
            ]
        }
      }
      replicas = 1
    })
  ]
}
