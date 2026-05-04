resource "aws_apigatewayv2_api" "api" { 
  # Se opta por HTTP API para optimizar latencia y costos en la ingesta asíncrona
  name          = "image-api-${terraform.workspace}"
  protocol_type = "HTTP"
  
  cors_configuration { 
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
  }
}

resource "aws_apigatewayv2_stage" "default" { 
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "upload_integration" { 
  # Integración tipo AWS_PROXY para delegar el parseo del request a la Lambda
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.upload.invoke_arn
}

resource "aws_apigatewayv2_route" "upload_route" { 
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}

resource "aws_lambda_permission" "api_gw" { 
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}