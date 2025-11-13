# EBS-based storage instead of EFS
# Saves ~$40/month by using EBS volumes instead of EFS

resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = "ebs-gp3-optimized"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    encrypted  = "true"
  }
}

# Remove EFS completely - use EBS volumes for persistent storage
# Each microservice gets its own EBS volume when needed
# Cost: ~$0.08/GB/month vs EFS $0.30/GB/month
