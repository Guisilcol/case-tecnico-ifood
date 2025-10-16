data "databricks_current_metastore" "this" {}

resource "aws_iam_role" "databricks_role" {
  name = "databricks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
        },
        Action = "sts:AssumeRole",
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/databricks-role"
        },
        Action = "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_iam_role_policy" "databricks_policy" {
  name = "databricks-pipeline-policy"
  role = aws_iam_role.databricks_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_landing_zone}",
          "arn:aws:s3:::${var.bucket_landing_zone}/*",
          "arn:aws:s3:::${var.bucket_bronze_layer}",
          "arn:aws:s3:::${var.bucket_bronze_layer}/*",
          "arn:aws:s3:::${var.bucket_silver_layer}",
          "arn:aws:s3:::${var.bucket_silver_layer}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.databricks_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:*",
          "states:*"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "databricks_credential" "databricks_credential" {
  name    = "databricks-read-s3-landing-zone"
  purpose = "STORAGE"

  aws_iam_role {
    role_arn = aws_iam_role.databricks_role.arn

  }
}

resource "databricks_external_location" "landing_zone" {
  name            = "landing-zone"
  url             = "s3://${var.bucket_landing_zone}/"
  credential_name = databricks_credential.databricks_credential.name
  comment         = "External location for landing zone data"

  depends_on = [
    aws_iam_role_policy.databricks_policy,
    aws_s3_bucket.bucket_landing_zone
  ]
}

resource "databricks_external_location" "bronze_layer" {
  name            = "bronze-layer"
  url             = "s3://${var.bucket_bronze_layer}/"
  credential_name = databricks_credential.databricks_credential.name
  comment         = "External location for bronze layer data"

  depends_on = [
    aws_iam_role_policy.databricks_policy,
    aws_s3_bucket.bucket_bronze_layer
  ]
}

resource "databricks_external_location" "silver_layer" {
  name            = "silver-layer"
  url             = "s3://${var.bucket_silver_layer}/"
  credential_name = databricks_credential.databricks_credential.name
  comment         = "External location for silver layer data"

  depends_on = [
    aws_iam_role_policy.databricks_policy,
    aws_s3_bucket.bucket_silver_layer
  ]
}


