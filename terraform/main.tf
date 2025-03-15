provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for storing raw data
resource "aws_s3_bucket" "data_lake" {
  bucket = "ag-my-data-lake-etl-bucket"
}

# IAM Role for AWS Glue
resource "aws_iam_role" "glue_role" {
  name = "GlueETLRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach necessary policies to Glue IAM Role
resource "aws_iam_policy_attachment" "glue_s3_access" {
  name       = "GlueS3Access"
  roles      = [aws_iam_role.glue_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach CloudWatch Logs permissions to IAM Role
resource "aws_iam_policy_attachment" "glue_logging" {
  name       = "glue-logging-policy-attachment"
  roles      = [aws_iam_role.glue_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Create CloudWatch Log Group for Glue Job Logs
resource "aws_cloudwatch_log_group" "glue_log_group" {
  name = "/aws-glue/jobs/glue-etl-job"
}

# RDS MySQL Database
resource "aws_db_instance" "rds_mysql" {
  allocated_storage    = 20
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  identifier          = "my-rds-database"
  username           = "admin"
  password           = var.db_password
  skip_final_snapshot = true
}

# AWS Glue Job
resource "aws_glue_job" "glue_etl" {
  name     = "glue-etl-job"
  role_arn = aws_iam_role.glue_role.arn
  command {
    script_location = "s3://${aws_s3_bucket.data_lake.bucket}/glue-scripts/glue_etl.py"
    python_version  = "3"
  }
  default_arguments = {
    "--TempDir"              = "s3://${aws_s3_bucket.data_lake.bucket}/temp/"
    "--enable-metrics"       = "true"
    "--enable-continuous-log" = "true"
    "--enable-glue-datacatalog" = "true"
    "--log-group-name"         = aws_cloudwatch_log_group.glue_log_group.name
  }

  execution_property {
    max_concurrent_runs = 1
  }
}
