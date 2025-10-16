variable "bucket_source_code" {
  description = "Nome do bucket S3 para armazenar o código fonte"
  type        = string
}

variable "bucket_landing_zone" {
  description = "Nome do bucket S3 para a landing zone"
  type        = string
}

variable "bucket_bronze_layer" {
  description = "Nome do bucket S3 para a camada bronze"
  type        = string
}

variable "bucket_silver_layer" {
  description = "Nome do bucket S3 para a camada silver"
  type        = string
}

variable "bucket_gold_layer" {
  description = "Nome do bucket S3 para a camada gold"
  type        = string
}

variable "databricks_host" {
  description = "URL do workspace Databricks"
  type        = string
}

variable "databricks_token" {
  description = "Token de acesso ao Databricks"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "Perfil AWS CLI"
  type        = string
  default     = "default"
}

variable "databricks_serverless_workspace_id" {
  description = "ID do workspace serverless do Databricks"
  type        = string
}
