export DATABRICKS_HOST=https://xxx.cloud.databricks.com/
export DATABRICKS_ACCOUNT_ID=123
export DATABRICKS_TOKEN=123
export DATABRICKS_SERVERLESS_COMPUTE_ID=auto

export bucket_landing_zone=bucket-landing-zone-
export bucket_bronze_layer=bucket-bronze-layer-
export bucket_silver_layer=bucket-silver-layer-
export aws_region=us-east-2
export aws_profile=default
export aws_access_key_id=ABC123
export aws_secret_access_key=ABC123
export databricks_serverless_workspace_id=123

export TF_VAR_bucket_landing_zone=${bucket_landing_zone}
export TF_VAR_bucket_bronze_layer=${bucket_bronze_layer}
export TF_VAR_bucket_silver_layer=${bucket_silver_layer}
export TF_VAR_databricks_host=${DATABRICKS_HOST}
export TF_VAR_databricks_token=${DATABRICKS_CLIENT_SECRET}
export TF_VAR_aws_region=${aws_region}
export TF_VAR_aws_profile=${aws_profile}
export TF_VAR_databricks_serverless_workspace_id=${databricks_serverless_workspace_id}
export TF_VAR_aws_access_key_id=${aws_access_key_id}
export TF_VAR_aws_secret_access_key=${aws_secret_access_key}
