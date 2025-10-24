##############################
# EventBridge Rules / CloudWatch alarms
##############################

# =====================================================
# EKS CLUSTER ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "eks_critical" {
  name        = "${var.cluster_name}-eks-critical-events"
  description = "Critical EKS cluster events"

  event_pattern = jsonencode({
    source = ["aws.eks"]
    region = ["af-south-1"]
    detail-type = [
      "EKS Cluster State Change",
      "EKS Node Group State Change"
    ]
    detail = {
      status = [
        "FAILED",
        "DEGRADED",
        "UPDATE_FAILED",
        "CREATE_FAILED",
        "DELETE_FAILED"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "eks_critical" {
  rule      = aws_cloudwatch_event_rule.eks_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# EC2 / KARPENTER / SPOT INTERRUPTION ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "ec2_spot_interruption" {
  name        = "${var.cluster_name}-spot-interruption"
  description = "EC2 Spot Instance interruption warnings"

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    region = ["af-south-1"]
    detail-type = [
      "EC2 Spot Instance Interruption Warning",
      "EC2 Instance Rebalance Recommendation"
    ]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ec2_spot_interruption" {
  rule      = aws_cloudwatch_event_rule.ec2_spot_interruption.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.warning_alerts.arn
}

resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "${var.cluster_name}-ec2-state-critical"
  description = "EC2 instance critical state changes"

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    region = ["af-south-1"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = [
        "stopped",
        "stopping",
        "terminated",
        "terminating"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ec2_state_change" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# AURORA DATABASE ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "aurora_critical" {
  name        = "${var.cluster_name}-aurora-critical"
  description = "Aurora database critical events"

  event_pattern = jsonencode({
    source = ["aws.rds"]
    region = ["af-south-1"]
    detail-type = [
      "RDS DB Cluster Event",
      "RDS DB Instance Event"
    ]
    detail = {
      EventCategories = [
        "failover",
        "failure",
        "maintenance"
      ]
      Message = [{
        prefix = "Failover"
      }, {
        prefix = "Multi-AZ"
      }, {
        prefix = "failure"
      }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "aurora_critical" {
  rule      = aws_cloudwatch_event_rule.aurora_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

resource "aws_cloudwatch_event_rule" "aurora_autoscaling" {
  name        = "${var.cluster_name}-aurora-autoscaling"
  description = "Aurora auto scaling events"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    region      = ["af-south-1"]
    detail-type = ["RDS DB Cluster Event"]
    detail = {
      EventCategories = ["configuration change"]
      Message = [{
        prefix = "Added"
      }, {
        prefix = "Removed"
      }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "aurora_autoscaling" {
  rule      = aws_cloudwatch_event_rule.aurora_autoscaling.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.info_alerts.arn
}

# =====================================================
# ELASTICACHE REDIS ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "elasticache_critical" {
  name        = "${var.cluster_name}-elasticache-critical"
  description = "ElastiCache critical events"

  event_pattern = jsonencode({
    source = ["aws.elasticache"]
    region = ["af-south-1"]
    detail-type = [
      "ElastiCache Event",
      "ElastiCache Notification"
    ]
    detail = {
      EventDescription = [{
        prefix = "Failover"
      }, {
        prefix = "Node"
      }, {
        prefix = "Cluster"
      }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "elasticache_critical" {
  rule      = aws_cloudwatch_event_rule.elasticache_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# EFS / EBS STORAGE ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "efs_critical" {
  name        = "${var.cluster_name}-efs-critical"
  description = "EFS critical events"

  event_pattern = jsonencode({
    source = ["aws.efs"]
    region = ["af-south-1"]
    detail-type = [
      "EFS File System State Change",
      "EFS Mount Target State Change"
    ]
    detail = {
      status = [
        "error",
        "deleted",
        "deleting"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "efs_critical" {
  rule      = aws_cloudwatch_event_rule.efs_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

resource "aws_cloudwatch_event_rule" "ebs_snapshot_failure" {
  name        = "${var.cluster_name}-ebs-snapshot-failure"
  description = "EBS snapshot failures"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    region      = ["af-south-1"]
    detail-type = ["EBS Snapshot Notification"]
    detail = {
      result = ["failed"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ebs_snapshot_failure" {
  rule      = aws_cloudwatch_event_rule.ebs_snapshot_failure.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.warning_alerts.arn
}

# =====================================================
# ALB / CLOUDFRONT ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "alb_critical" {
  name        = "${var.cluster_name}-alb-critical"
  description = "Application Load Balancer critical events"

  event_pattern = jsonencode({
    source = ["aws.elasticloadbalancing"]
    region = ["af-south-1"]
    detail-type = [
      "AWS API Call via CloudTrail"
    ]
    detail = {
      eventName = [
        "DeleteLoadBalancer",
        "DeleteTargetGroup",
        "DeregisterTargets"
      ]
      errorCode = [{
        exists = true
      }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "alb_critical" {
  rule      = aws_cloudwatch_event_rule.alb_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# SECURITY & IAM ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "security_critical" {
  name        = "${var.cluster_name}-security-critical"
  description = "Critical security events"

  event_pattern = jsonencode({
    source = ["aws.iam", "aws.sts", "aws.kms"]
    region = ["af-south-1"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        # IAM dangerous operations
        "DeleteRole",
        "DeletePolicy",
        "DeleteUser",
        "DeleteAccessKey",
        "PutUserPolicy",
        "AttachUserPolicy",
        "AttachRolePolicy",
        
        # KMS operations
        "DisableKey",
        "ScheduleKeyDeletion",
        
        # Root account usage
        "ConsoleLogin"
      ]
      userIdentity = {
        type = ["Root"]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "security_critical" {
  rule      = aws_cloudwatch_event_rule.security_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

resource "aws_cloudwatch_event_rule" "failed_auth" {
  name        = "${var.cluster_name}-failed-authentication"
  description = "Failed authentication attempts"

  event_pattern = jsonencode({
    source      = ["aws.signin"]
    region      = ["af-south-1"]
    detail-type = ["AWS Console Sign In via CloudTrail"]
    detail = {
      eventName = ["ConsoleLogin"]
      errorCode = ["Failed authentication"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "failed_auth" {
  rule      = aws_cloudwatch_event_rule.failed_auth.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.warning_alerts.arn
}

# =====================================================
# NETWORK / VPC ALERTS
# =====================================================

resource "aws_cloudwatch_event_rule" "vpc_critical" {
  name        = "${var.cluster_name}-vpc-critical"
  description = "VPC critical changes"

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    region = ["af-south-1"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "DeleteVpc",
        "DeleteSubnet",
        "DeleteInternetGateway",
        "DeleteNatGateway",
        "DeleteVpcEndpoint",
        "DeleteRouteTable",
        "DeleteSecurityGroup",
        "RevokeSecurityGroupIngress",
        "RevokeSecurityGroupEgress"
      ]
      requestParameters = {
        vpcId = [var.vpc_id]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "vpc_critical" {
  rule      = aws_cloudwatch_event_rule.vpc_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# CLOUDWATCH ALARMS STATE CHANGE
# =====================================================

resource "aws_cloudwatch_event_rule" "alarm_state_change" {
  name        = "${var.cluster_name}-alarm-state-change"
  description = "CloudWatch Alarm state changes"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    region      = ["af-south-1"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "alarm_state_change" {
  rule      = aws_cloudwatch_event_rule.alarm_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# COST ANOMALY DETECTION
# =====================================================

resource "aws_cloudwatch_event_rule" "cost_anomaly" {
  name        = "${var.cluster_name}-cost-anomaly"
  description = "Cost anomaly detection alerts"

  # EventBridge can't use numericGreaterThan in the pattern; match Cost Anomaly Detection events broadly
  event_pattern = jsonencode({
    source      = ["aws.ce"]
    "detail-type" = ["Cost Anomaly Detection"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "cost_anomaly" {
  rule      = aws_cloudwatch_event_rule.cost_anomaly.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.warning_alerts.arn
}

# =====================================================
# AWS HEALTH EVENTS
# =====================================================

resource "aws_cloudwatch_event_rule" "health_events" {
  name        = "${var.cluster_name}-health-events"
  description = "AWS Health Dashboard events"

  event_pattern = jsonencode({
    source = ["aws.health"]
    detail-type = [
      "AWS Health Event",
      "AWS Health Abuse Event"
    ]
    detail = {
      eventTypeCategory = [
        "issue",
        "accountNotification",
        "scheduledChange"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "health_events" {
  rule      = aws_cloudwatch_event_rule.health_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}

# =====================================================
# SNS PERMISSIONS FOR EVENTBRIDGE
# =====================================================

resource "aws_sns_topic_policy" "critical_alerts" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.critical_alerts.arn
    }]
  })
}

# =====================================================
# Metric Alarms: RDS/Aurora CPU & FreeableMemory
# =====================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  for_each = toset(var.rds_cluster_identifiers)
  alarm_name          = "${each.value}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  threshold           = 80
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions = {
    DBClusterIdentifier = each.value
  }
  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  for_each = toset(var.rds_cluster_identifiers)
  alarm_name          = "${each.value}-freeable-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 150000000  # ~150 MB; adjust per instance class via variable if needed
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  dimensions = {
    DBClusterIdentifier = each.value
  }
  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

# =====================================================
# DocumentDB (DocDB) CPU & FreeableMemory
# =====================================================

resource "aws_cloudwatch_metric_alarm" "docdb_cpu_high" {
  for_each = toset(var.docdb_cluster_identifiers)
  alarm_name          = "${each.value}-docdb-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  threshold           = 80
  namespace           = "AWS/DocDB"
  metric_name         = "CPUUtilization"
  dimensions = {
    DBClusterIdentifier = each.value
  }
  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "docdb_freeable_memory_low" {
  for_each = toset(var.docdb_cluster_identifiers)
  alarm_name          = "${each.value}-docdb-freeable-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 150000000
  namespace           = "AWS/DocDB"
  metric_name         = "FreeableMemory"
  dimensions = {
    DBClusterIdentifier = each.value
  }
  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

# =====================================================
# ElastiCache (Redis) CPU and Evictions
# =====================================================

resource "aws_cloudwatch_metric_alarm" "elasticache_cpu_high" {
  for_each = toset(var.elasticache_cluster_ids)
  alarm_name          = "${each.value}-elasticache-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  threshold           = 80
  namespace           = "AWS/ElastiCache"
  metric_name         = "CPUUtilization"
  dimensions = {
    CacheClusterId = each.value
  }
  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "elasticache_evictions" {
  for_each = toset(var.elasticache_cluster_ids)
  alarm_name          = "${each.value}-elasticache-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  namespace           = "AWS/ElastiCache"
  metric_name         = "Evictions"
  dimensions = {
    CacheClusterId = each.value
  }
  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

# =====================================================
# ALB traffic spike alarms
# =====================================================

resource "aws_cloudwatch_metric_alarm" "alb_request_spike" {
  for_each = toset(var.alb_names)
  alarm_name          = "${each.value}-alb-request-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = var.request_count_threshold
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RequestCount"
  dimensions = {
    LoadBalancer = each.value
  }
  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]
  tags = var.tags
}

resource "aws_sns_topic_policy" "warning_alerts" {
  arn = aws_sns_topic.warning_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.warning_alerts.arn
    }]
  })
}

resource "aws_sns_topic_policy" "info_alerts" {
  arn = aws_sns_topic.info_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.info_alerts.arn
    }]
  })
}

# =====================================================
# CLOUDWATCH ALERTS MODULE
# =====================================================

# EKS CLUSTER METRICS
resource "aws_cloudwatch_metric_alarm" "eks_node_count_low" {
  alarm_name          = "${var.cluster_name}-node-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_node_count"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 3
  alarm_description   = "Alert when node count drops below 3"
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "eks_pod_count_high" {
  alarm_name          = "${var.cluster_name}-pod-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_number_of_running_pods"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Alert when pod count exceeds 1000"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "eks_cpu_high" {
  alarm_name          = "${var.cluster_name}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when cluster CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "eks_memory_high" {
  alarm_name          = "${var.cluster_name}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alert when cluster memory exceeds 85%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

# Aurora alarms
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "${var.cluster_name}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Aurora CPU exceeds 80%"

  dimensions = {
    DBClusterIdentifier = "${var.cluster_name}-aurora"
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections_high" {
  alarm_name          = "${var.cluster_name}-aurora-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Aurora connections exceed 80"

  dimensions = {
    DBClusterIdentifier = "${var.cluster_name}-aurora"
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  alarm_name          = "${var.cluster_name}-aurora-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraReplicaLag"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Alert when Aurora replica lag exceeds 1000ms"

  dimensions = {
    DBClusterIdentifier = "${var.cluster_name}-aurora"
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

# ElastiCache alarms
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "${var.cluster_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alert when Redis CPU exceeds 75%"

  dimensions = {
    ReplicationGroupId = "${var.cluster_name}-redis"
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_high" {
  alarm_name          = "${var.cluster_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alert when Redis memory exceeds 85%"

  dimensions = {
    ReplicationGroupId = "${var.cluster_name}-redis"
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  alarm_name          = "${var.cluster_name}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Alert when Redis evictions exceed 100"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = "${var.cluster_name}-redis"
  }

  alarm_actions = [aws_sns_topic.warning_alerts.arn]
  ok_actions    = [aws_sns_topic.info_alerts.arn]

  tags = var.tags
}
