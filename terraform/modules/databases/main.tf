resource "aws_docdb_subnet_group" "main" {
  name       = "${var.cluster_name}-docdb-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.cluster_name}-docdb-subnet-group"
  }
}

resource "aws_security_group" "docdb" {
  name_prefix = "${var.cluster_name}-docdb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "Allow EKS nodes"
    cidr_blocks = var.private_subnet_cidrs
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "Allow RDS subnets"
    cidr_blocks = var.private_rds_subnet_cidrs
  }

  tags = {
    Name = "${var.cluster_name}-docdb-sg"
  }
}

resource "random_password" "docdb" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "docdb_credentials" {
  name        = "${var.cluster_name}-docdb-credentials"
  description = "DocumentDB credentials for ${var.cluster_name}"
}

resource "aws_secretsmanager_secret_version" "docdb_credentials_version" {
  secret_id     = aws_secretsmanager_secret.docdb_credentials.id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.docdb.result
  })
}

data "aws_secretsmanager_secret" "docdb_credentials" {
  name = aws_secretsmanager_secret.docdb_credentials.name
}

data "aws_secretsmanager_secret_version" "docdb_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.docdb_credentials.id
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.cluster_name}-docdb"
  engine                  = "docdb"
  master_username         = jsondecode(data.aws_secretsmanager_secret_version.docdb_credentials_version.secret_string).username
  master_password         = jsondecode(data.aws_secretsmanager_secret_version.docdb_credentials_version.secret_string).password
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  db_subnet_group_name    = aws_docdb_subnet_group.main.name
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  storage_encrypted       = true
  skip_final_snapshot     = true

  tags = {
    Name = "${var.cluster_name}-docdb"
  }
}

resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${var.cluster_name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_docdb_cluster.main.engine

  tags = {
    Name = "${var.cluster_name}-docdb-${count.index}"
  }
}
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
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow EKS nodes"
    cidr_blocks = var.private_subnet_cidrs
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow RDS subnets"
    cidr_blocks = var.private_rds_subnet_cidrs
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

resource "random_password" "db" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.cluster_name}-db-credentials"
  description = "Database credentials for ${var.cluster_name}"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.db.result
  })
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = aws_secretsmanager_secret.db_credentials.name
}

data "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.cluster_name}-aurora"
  engine             = "aurora-postgresql"
  engine_version     = "15.8"
  database_name      = "wasaadb"
  master_username    = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string).username
  master_password    = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string).password

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