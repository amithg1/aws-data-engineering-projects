output "s3_bucket_name" {
  value = aws_s3_bucket.data_lake.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.rds_mysql.endpoint
}

output "glue_job_name" {
  value = aws_glue_job.glue_etl.name
}