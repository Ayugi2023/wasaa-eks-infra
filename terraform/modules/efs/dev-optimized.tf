# Development-optimized EFS configuration
# Uses Infrequent Access storage class and smaller provisioned throughput

resource "aws_efs_file_system" "dev_optimized" {
  creation_token = "${var.cluster_name}-efs-dev"
  
  # Use One Zone storage class for 47% cost savings
  availability_zone_name = data.aws_availability_zones.available.names[0]
  
  performance_mode = "generalPurpose"
  
  # Use provisioned throughput with minimal settings
  throughput_mode                = "provisioned"
  provisioned_throughput_in_mibps = 10  # Minimal for development
  
  encrypted = true
  kms_key_id = var.kms_key_id
  
  # Enable lifecycle policy to move to IA after 7 days
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
  
  tags = {
    Name          = "${var.cluster_name}-efs-dev"
    Environment   = "development"
    CostOptimized = "true"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Single mount target in one AZ only
resource "aws_efs_mount_target" "dev" {
  file_system_id  = aws_efs_file_system.dev_optimized.id
  subnet_id       = var.private_subnet_ids[0]  # Only first subnet
  security_groups = [aws_security_group.efs.id]
}
