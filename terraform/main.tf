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
}
