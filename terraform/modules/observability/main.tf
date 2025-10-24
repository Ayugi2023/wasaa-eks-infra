resource "aws_prometheus_workspace" "main" {
  alias = "${var.cluster_name}-prometheus"

  tags = {
    Name = "${var.cluster_name}-prometheus"
  }
}

# Grafana workspace not available in af-south-1 region
# Will use self-hosted Grafana via Ansible

resource "aws_dlm_lifecycle_policy" "ebs" {
  description        = "EBS snapshot lifecycle policy"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types   = ["VOLUME"]
    target_tags = {
      Snapshot = "true"
    }

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }
  }

  tags = {
    Name = "${var.cluster_name}-ebs-lifecycle"
  }
}

resource "aws_iam_role" "dlm" {
  name = "${var.cluster_name}-dlm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
  role       = aws_iam_role.dlm.name
}