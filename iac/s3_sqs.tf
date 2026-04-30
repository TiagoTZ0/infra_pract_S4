# S3 Bucket
resource "aws_s3_bucket" "images" {
  bucket        = "image-processor-${terraform.workspace}-images-${var.bucket_suffix}"
  force_destroy = true # Para que deje borrar todo con terraform destroy
}

# SQS DLQ y Main
resource "aws_sqs_queue" "dlq" {
  name                      = "image-processor-${terraform.workspace}-dlq"
  message_retention_seconds = 1209600 # 14 dias
}

resource "aws_sqs_queue" "main" {
  name                       = "image-processor-${terraform.workspace}-queue"
  visibility_timeout_seconds = 360
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# Permiso para que S3 escriba en SQS
resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = aws_sqs_queue.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main.arn
      Condition = {
        ArnLike = { "aws:SourceArn" = aws_s3_bucket.images.arn }
      }
    }]
  })
}

# Notificación de S3 a SQS
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.images.id
  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
  depends_on = [aws_sqs_queue_policy.s3_to_sqs]
}