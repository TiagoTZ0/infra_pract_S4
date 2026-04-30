variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_suffix" {
  description = "Sufijo único para el bucket S3"
  type        = string
  default     = "tiago-trigoso-2006120113"
}