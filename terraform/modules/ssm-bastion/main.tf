# Instance Profile for Bastion
# Instance Profile for Bastion
resource "aws_iam_instance_profile" "ssm_bastion" {
  name = "${var.cluster_name}-ssm-bastion"
  role = aws_iam_role.ssm_bastion.name
  tags = var.tags
}
# IAM Role for SSM Bastion Pod
resource "aws_iam_role" "ssm_bastion" {
  name = "${var.cluster_name}-ssm-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::561810056018:oidc-provider/oidc.eks.af-south-1.amazonaws.com/id/183E3DFAF4073200C6C4E544C831F0AC"
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" : "system:serviceaccount:default:ssm-bastion",
          "${var.oidc_provider}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# SSM Policy for Bastion
resource "aws_iam_policy" "ssm_bastion" {
  name        = "${var.cluster_name}-ssm-bastion"
  description = "Policy for SSM bastion pod"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:GetMessages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ssm/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_bastion" {
  role       = aws_iam_role.ssm_bastion.name
  policy_arn = aws_iam_policy.ssm_bastion.arn
}

# CloudWatch Log Group for Session Logs
resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/aws/ssm/${var.cluster_name}/sessions"
  retention_in_days = 30
  tags = var.tags
}

# Outputs
output "ssm_bastion_role_arn" {
  value = aws_iam_role.ssm_bastion.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.ssm_sessions.name
}

# Security Group for Bastion
resource "aws_security_group" "ssm_bastion" {
  name        = "${var.cluster_name}-ssm-bastion-sg"
  description = "Security group for SSM bastion instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For debugging, restrict in production
  }

  # Allow outbound access to DocumentDB, PostgreSQL, and Redis
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound to DocumentDB"
  }
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound to PostgreSQL"
  }
  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound to Redis"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# EC2 Bastion Instance
/*
resource "aws_instance" "ssm_bastion" {
  ami                    = var.bastion_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.bastion_subnet_id
  vpc_security_group_ids = [aws_security_group.ssm_bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_bastion.name
  key_name               = var.bastion_key_name
  tags                   = var.tags
  depends_on             = [aws_iam_instance_profile.ssm_bastion]
}
*/
