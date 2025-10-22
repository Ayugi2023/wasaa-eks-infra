resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.cluster_name}-aurora"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  database_name      = "wasaadb"
  master_username    = "postgres"
  master_password    = "changeme123!"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  storage_encrypted = true
  kms_key_id        = var.kms_key_id
  skip_final_snapshot = true

  tags = {
    Name = "${var.cluster_name}-aurora"
  }
}

resource "aws_rds_cluster_instance" "main" {
  count              = 2
  identifier         = "${var.cluster_name}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Name = "${var.cluster_name}-aurora-${count.index}"
  }
}

resource "aws_appautoscaling_target" "aurora" {
  max_capacity       = 5
  min_capacity       = 2
  resource_id        = "cluster:${aws_rds_cluster.main.cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "aurora" {
  name               = "${var.cluster_name}-aurora-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aurora.resource_id
  scalable_dimension = aws_appautoscaling_target.aurora.scalable_dimension
  service_namespace  = aws_appautoscaling_target.aurora.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value = 70.0
  }
}