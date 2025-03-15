import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Initialize Spark Session
spark = SparkSession.builder \
    .appName("AWS Glue ETL") \
    .getOrCreate()

# S3 bucket path
s3_path = "s3://ag-my-data-lake-etl-bucket/raw-data/*.json"

# Read JSON data from S3
df = spark.read.json(s3_path)

# Data Transformation (renaming columns, removing nulls)
df_clean = df.withColumnRenamed("field1", "name") \
             .withColumnRenamed("field2", "email") \
             .dropna()

# Database credentials
jdbc_url = "jdbc:mysql://my-rds-database.cmf042mmsqvq.us-east-1.rds.amazonaws.com:3306/mysql"
db_properties = {
    "user": "admin",
    "password": "password",
    "driver": "com.mysql.cj.jdbc.Driver"
}

# Write to RDS MySQL table
df_clean.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "users") \
    .option("user", db_properties["user"]) \
    .option("password", db_properties["password"]) \
    .mode("append") \
    .save()

print("Data successfully written to RDS!")

