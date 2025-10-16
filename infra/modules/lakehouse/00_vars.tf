
variable "bronze_db_name" {
  description = "Nome do banco de dados bronze"
  type        = string
}

variable "bronze_db_s3_location" {
  description = "Caminho S3 do banco de dados bronze"
  type        = string
}

variable "silver_db_name" {
  description = "Nome do banco de dados silver"
  type        = string
}

variable "silver_db_s3_location" {
  description = "Caminho S3 do banco de dados silver"
  type        = string
}

variable "gold_db_name" {
  description = "Nome do banco de dados gold"
  type        = string
}

variable "gold_db_s3_location" {
  description = "Caminho S3 do banco de dados gold"
  type        = string
}




