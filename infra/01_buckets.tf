resource "aws_s3_bucket" "bucket_source_code" {
  bucket = var.bucket_source_code

  tags = {
    name = "Source Code Bucket"
  }
}

resource "aws_s3_bucket" "bucket_landing_zone" {
  bucket = var.bucket_landing_zone

  tags = {
    name = "Landing Zone Bucket"
  }
}

resource "aws_s3_bucket" "bucket_bronze_layer" {
  bucket = var.bucket_bronze_layer

  tags = {
    name = "Bronze Layer Bucket"
  }
}

resource "aws_s3_bucket" "bucket_silver_layer" {
  bucket = var.bucket_silver_layer

  tags = {
    name = "Silver Layer Bucket"
  }
}
