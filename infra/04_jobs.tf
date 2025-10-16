
resource "aws_glue_job" "download_nyc_taxi_yellow" {
  name     = "glue-job-download-nyc-taxi"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${var.bucket_source_code}/src/jobs/download_nyc_taxi_data.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--enable-job-insights" = "true"
    "--extra-py-files"      = "s3://${var.bucket_source_code}/src/dist/shared-0.1.0-py3-none-any.whl"
    "library-set"           = "analytics"
  }

  max_capacity = 0.0625 # DPU for Python Shell jobs (0.0625 or 1)
}

resource "aws_glue_job" "glue_job_bronze_nyc_taxi_data_forhire" {
  name     = "glue-job-bronze-nyc-taxi-data-forhire"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${var.bucket_source_code}/src/jobs/bronze_nyc_taxi_data_forhire.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--source_path"  = "s3://${var.bucket_landing_zone}/nyc_taxi_data_forhire/"
    "--target_db"    = "bronze_db"
    "--target_table" = "nyc_taxi_data_forhire"

    "--job-language"        = "python"
    "--enable-job-insights" = "true"
    "--extra-py-files"      = "s3://${var.bucket_source_code}/src/dist/shared-0.1.0-py3-none-any.whl"
    "library-set"           = "analytics"
  }

  max_capacity = 1
}

resource "aws_glue_job" "glue_job_bronze_nyc_taxi_data_green" {
  name     = "glue-job-bronze-nyc-taxi-data-green"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${var.bucket_source_code}/src/jobs/bronze_nyc_taxi_data_green.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--source_path"  = "s3://${var.bucket_landing_zone}/nyc_taxi_data_green/"
    "--target_db"    = "bronze_db"
    "--target_table" = "nyc_taxi_data_green"

    "--job-language"        = "python"
    "--enable-job-insights" = "true"
    "--extra-py-files"      = "s3://${var.bucket_source_code}/src/dist/shared-0.1.0-py3-none-any.whl"
    "library-set"           = "analytics"
  }

  max_capacity = 1
}

resource "aws_glue_job" "glue_job_bronze_nyc_taxi_data_highvolumeforhire" {
  name     = "glue-job-bronze-nyc-taxi-data-highvolumeforhire"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${var.bucket_source_code}/src/jobs/bronze_nyc_taxi_data_highvolumeforhire.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--source_path"  = "s3://${var.bucket_landing_zone}/nyc_taxi_data_highvolumeforhire/"
    "--target_db"    = "bronze_db"
    "--target_table" = "nyc_taxi_data_highvolumeforhire"

    "--job-language"        = "python"
    "--enable-job-insights" = "true"
    "--extra-py-files"      = "s3://${var.bucket_source_code}/src/dist/shared-0.1.0-py3-none-any.whl"
    "library-set"           = "analytics"
  }

  max_capacity = 1
}

