##############################
# SNS Topics & Lambda Wiring
##############################

# SNS Topic for Critical Alerts
resource "aws_sns_topic" "critical_alerts" {
  name              = "${var.cluster_name}-critical-alerts"
  display_name      = "Critical Infrastructure Alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, {
    AlertLevel = "critical"
  })
}

# SNS Topic for Warning Alerts
resource "aws_sns_topic" "warning_alerts" {
  name              = "${var.cluster_name}-warning-alerts"
  display_name      = "Warning Infrastructure Alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, {
    AlertLevel = "warning"
  })
}

# SNS Topic for Info Alerts
resource "aws_sns_topic" "info_alerts" {
  name              = "${var.cluster_name}-info-alerts"
  display_name      = "Info Infrastructure Alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, {
    AlertLevel = "info"
  })
}

# Email Subscriptions
resource "aws_sns_topic_subscription" "critical_email" {
  for_each  = toset(var.critical_email_addresses)
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "warning_email" {
  for_each  = toset(var.warning_email_addresses)
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# IAM Role for Lambda
resource "aws_iam_role" "slack_lambda" {
  name = "${var.cluster_name}-slack-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.slack_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Slack lambda to read Slack webhook secret from Secrets Manager if configured
resource "aws_iam_role_policy" "slack_lambda_secrets" {
  name = "${var.cluster_name}-slack-lambda-secrets"
  role = aws_iam_role.slack_lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = var.slack_secret_arn != "" ? var.slack_secret_arn : "*"
      }
    ]
  })
}

# Package Lambda function
data "archive_file" "slack_lambda" {
  type        = "zip"
  output_path = "${path.module}/slack_lambda.zip"
  source {
    content  = file("${path.module}/slack_lambda.py")
    filename = "index.py"
  }
}

# Lambda for Slack Integration (Critical)
resource "aws_lambda_function" "slack_critical" {
  filename         = data.archive_file.slack_lambda.output_path
  function_name    = "${var.cluster_name}-slack-critical-alerts"
  role             = aws_iam_role.slack_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.slack_lambda.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_critical_webhook_url
      CLUSTER_NAME      = var.cluster_name
      ALERT_LEVEL       = "CRITICAL"
    }
  }

  tags = var.tags
}

# Lambda for Slack Integration (Warning)
resource "aws_lambda_function" "slack_warning" {
  filename         = data.archive_file.slack_lambda.output_path
  function_name    = "${var.cluster_name}-slack-warning-alerts"
  role             = aws_iam_role.slack_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.slack_lambda.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_warning_webhook_url
      CLUSTER_NAME      = var.cluster_name
      ALERT_LEVEL       = "WARNING"
    }
  }

  tags = var.tags
}

# SNS to Lambda subscription (Critical)
resource "aws_sns_topic_subscription" "critical_slack" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_critical.arn
}

# SNS to Lambda subscription (Warning)
resource "aws_sns_topic_subscription" "warning_slack" {
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_warning.arn
}

# Lambda permission for SNS (Critical)
resource "aws_lambda_permission" "sns_critical" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_critical.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.critical_alerts.arn
}

# Lambda permission for SNS (Warning)
resource "aws_lambda_permission" "sns_warning" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_warning.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.warning_alerts.arn
}

# =====================================================
# Instance launch watcher (detect autoscaler bursts)
# =====================================================

# DynamoDB table to store recent instance launch events
resource "aws_dynamodb_table" "instance_launch_events" {
  name           = "${var.cluster_name}-instance-launch-events"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "cluster"
  range_key      = "ts"

  attribute {
    name = "cluster"
    type = "S"
  }

  attribute {
    name = "ts"
    type = "N"
  }

  tags = var.tags
}

# Package instance launch watcher lambda
data "archive_file" "instance_launch_watcher" {
  type        = "zip"
  output_path = "${path.module}/instance_launch_watcher.zip"
  source {
    content  = file("${path.module}/instance_launch_watcher.py")
    filename = "index.py"
  }
}

# IAM role for the watcher Lambda
resource "aws_iam_role" "instance_watcher_role" {
  name = "${var.cluster_name}-instance-watcher-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "instance_watcher_policy" {
  name = "${var.cluster_name}-instance-watcher-policy"
  role = aws_iam_role.instance_watcher_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Resource = aws_dynamodb_table.instance_launch_events.arn
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = [aws_sns_topic.critical_alerts.arn, aws_sns_topic.warning_alerts.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda for counting instance launches
resource "aws_lambda_function" "instance_launch_watcher" {
  filename         = data.archive_file.instance_launch_watcher.output_path
  function_name    = "${var.cluster_name}-instance-launch-watcher"
  role             = aws_iam_role.instance_watcher_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.instance_launch_watcher.output_base64sha256
  runtime          = "python3.11"
  timeout          = 15

  environment {
    variables = {
      DDB_TABLE    = aws_dynamodb_table.instance_launch_events.name
      CLUSTER_NAME = var.cluster_name
      THRESHOLD    = tostring(var.autoscaler_instance_threshold)
      WINDOW_MIN   = tostring(var.autoscaler_window_minutes)
      SNS_TOPIC_ARN = aws_sns_topic.warning_alerts.arn
    }
  }

  tags = var.tags
}

# EventBridge rule to send EC2 instance state change events to the watcher lambda
resource "aws_cloudwatch_event_rule" "ec2_instance_running" {
  name        = "${var.cluster_name}-ec2-instance-running"
  description = "Detect EC2 instances entering running state for cluster and notify watcher"

  event_pattern = jsonencode({
    source = ["aws.ec2"],
    "detail-type" = ["EC2 Instance State-change Notification"],
    detail = { state = ["running"] }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ec2_instance_running_target" {
  rule      = aws_cloudwatch_event_rule.ec2_instance_running.name
  target_id = "InstanceWatcher"
  arn       = aws_lambda_function.instance_launch_watcher.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_watcher" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_launch_watcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_instance_running.arn
}
