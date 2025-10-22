resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.main.key_id
}