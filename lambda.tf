provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "generate_presigned_url" {
  filename         = "lambda_function.zip"
  function_name    = "generate_presigned_url"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.generate_presigned_url"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime          = "python3.8"

  environment {
    variables = {
      NOTEBOOK_INSTANCE_NAME = "my-notebook"
      SESSION_DURATION      = "1800"
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

data "archive_file" "lambda_function" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<EOF
import boto3

def generate_presigned_url(event, context):
    sagemaker = boto3.client('sagemaker')
    response = sagemaker.create_presigned_notebook_instance_url(
        NotebookInstanceName='${var.notebook_instance_name}',
        SessionExpirationDurationInSeconds=${var.session_duration}
    )
    return response['AuthorizedUrl']
EOF
    filename = "lambda_function.py"
  }
}

variable "notebook_instance_name" {
  default = "my-notebook"
}

variable "session_duration" {
  default = 1800
}
