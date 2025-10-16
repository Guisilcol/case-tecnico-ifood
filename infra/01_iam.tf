resource "aws_iam_role" "glue_job_role" {
  name = "glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "glue.amazonaws.com",
            "states.amazonaws.com",
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "data_pipeline_policy" {
  name = "data-pipeline-policy"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "glue:*",
          "states:*",
          "cloudwatch:*",
          "logs:*",
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role" "databricks_role" {
  name = "databricks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL",
            "arn:aws:iam::241963575180:role/databricks-role"
          ]
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "6ff02c0c-d789-4f2e-8185-344bd63a7f69"
          }
        }
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
        Resource = ["*"]
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
