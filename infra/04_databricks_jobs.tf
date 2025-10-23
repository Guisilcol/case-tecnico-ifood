
resource "databricks_job" "serverless_python_job" {
  name = "NYC_Taxi_Data_Processing_Job"

  environment {
    environment_key = "default"

    spec {
      client = "2"
      dependencies = [
        "boto3", "mypy-boto3", "boto3-stubs[s3]"
      ]
    }
  }

  # TASKS DE DOWNLOAD

  task {
    task_key        = "download_nyc_taxi_data_yellow"
    environment_key = "default"
    max_retries     = 0

    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/download_nyc_taxi_data.py"
      parameters  = ["yellow", "2023-01", "2023-05", "--s3-bucket", var.bucket_landing_zone, "--s3-prefix", "nyc_taxi_data_yellow"]
    }
  }

  task {
    task_key        = "download_nyc_taxi_data_green"
    environment_key = "default"
    max_retries     = 0

    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/download_nyc_taxi_data.py"
      parameters  = ["green", "2023-01", "2023-05", "--s3-bucket", var.bucket_landing_zone, "--s3-prefix", "nyc_taxi_data_green"]
    }
  }

  task {
    task_key        = "download_nyc_taxi_data_forhire"
    environment_key = "default"
    max_retries     = 0

    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/download_nyc_taxi_data.py"
      parameters  = ["forhire", "2023-01", "2023-05", "--s3-bucket", var.bucket_landing_zone, "--s3-prefix", "nyc_taxi_data_forhire"]
    }
  }

  task {
    task_key        = "download_nyc_taxi_data_highvolumeforhire"
    environment_key = "default"
    max_retries     = 0

    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/download_nyc_taxi_data.py"
      parameters  = ["highvolumeforhire", "2023-01", "2023-05", "--s3-bucket", var.bucket_landing_zone, "--s3-prefix", "nyc_taxi_data_highvolumeforhire"]
    }
  }

  # TASKS DE INGESTÃO PARA A BRONZE

  task {
    task_key        = "process_bronze_nyc_taxi_data_yellow"
    environment_key = "default"
    max_retries     = 0

    depends_on {
      task_key = "download_nyc_taxi_data_yellow"
    }
    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/bronze_layer_ingestion.py"
      parameters  = ["bronze_db.nyc_taxi_data_yellow", "s3://${var.bucket_landing_zone}/nyc_taxi_data_yellow"]
    }
  }

  task {
    task_key        = "process_bronze_nyc_taxi_data_green"
    environment_key = "default"
    max_retries     = 0

    depends_on {
      task_key = "download_nyc_taxi_data_green"
    }
    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/bronze_layer_ingestion.py"
      parameters  = ["bronze_db.nyc_taxi_data_green", "s3://${var.bucket_landing_zone}/nyc_taxi_data_green"]
    }
  }

  task {
    task_key        = "process_bronze_nyc_taxi_data_forhire"
    environment_key = "default"
    max_retries     = 0

    depends_on {
      task_key = "download_nyc_taxi_data_forhire"
    }
    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/bronze_layer_ingestion.py"
      parameters  = ["bronze_db.nyc_taxi_data_forhire", "s3://${var.bucket_landing_zone}/nyc_taxi_data_forhire"]
    }
  }

  task {
    task_key        = "process_bronze_nyc_taxi_data_highvolumeforhire"
    environment_key = "default"
    max_retries     = 0

    depends_on {
      task_key = "download_nyc_taxi_data_highvolumeforhire"
    }
    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/bronze_layer_ingestion.py"
      parameters  = ["bronze_db.nyc_taxi_data_highvolumeforhire", "s3://${var.bucket_landing_zone}/nyc_taxi_data_highvolumeforhire"]
    }
  }

  # TASK DE ETL PARA SILVER

  task {
    task_key        = "process_silver_nyc_taxi_data"
    environment_key = "default"
    max_retries     = 0

    depends_on {
      task_key = "process_bronze_nyc_taxi_data_yellow"
    }
    depends_on {
      task_key = "process_bronze_nyc_taxi_data_green"
    }

    spark_python_task {
      python_file = "${var.workspace_folder}/src/jobs/silver_layer_etl.py"
      parameters  = []
    }

  }
}
