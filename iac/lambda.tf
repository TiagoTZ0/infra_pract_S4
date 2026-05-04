data "archive_file" "upload_zip" { 
  type        = "zip"
  source_dir  = "${path.module}/../src/upload-lambda"
  output_path = "${path.module}/upload.zip"
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/crop-lambda"
  output_path = "${path.module}/crop.zip"
}

resource "aws_security_group" "lambda_sg" { 
  # Centraliza el tráfico de salida de las Lambdas hacia la VPC en este entorno de desarrollo.
  name   = "lambda-sg-${terraform.workspace}"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "upload" { 
  # Dimensionada a 256MB para optimizar costos en una operación ligera (solo enrutamiento de I/O).
  filename         = data.archive_file.upload_zip.output_path
  function_name    = "upload-lambda-${terraform.workspace}"
  role             = aws_iam_role.upload_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256 
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  environment {
    variables = { S3_BUCKET = aws_s3_bucket.images.bucket }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_function" "crop" { 
  # Capacidad ampliada a 512MB para soportar la carga de CPU intensiva que requiere Sharp.
  filename         = data.archive_file.crop_zip.output_path
  function_name    = "crop-lambda-${terraform.workspace}"
  role             = aws_iam_role.crop_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60
  memory_size      = 512 
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  environment {
    variables = { S3_BUCKET = aws_s3_bucket.images.bucket }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" { 
  # Desacopla la arquitectura y garantiza tolerancia a fallos mediante el consumo por lotes (batching).
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5
}