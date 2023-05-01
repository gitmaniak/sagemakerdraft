resource "aws_sagemaker_notebook_instance" "notebook_instance" {
  name                 = "my-notebook-instance"
  instance_type        = "ml.t2.medium"
  role_arn             = aws_iam_role.notebook_role.arn
  subnet_id            = aws_subnet.private.id
  security_group_ids   = [aws_security_group.notebook_security_group.id]
  lifecycle_config_name = "my-lifecycle-config"
}

resource "aws_iam_role" "notebook_role" {
  name = "my-notebook-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "notebook_policy_attachment" {
  policy_arn = aws_iam_policy.notebook_policy.arn
  roles      = [aws_iam_role.notebook_role.name]
}

resource "aws_iam_policy" "notebook_policy" {
  name = "my-notebook-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      },
      {
        Action = [
          "sagemaker:CreatePresignedNotebookInstanceUrl"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "notebook_security_group" {
  name_prefix = "my-notebook-security-group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# Define variables
variable "aws_region" {
  default = "us-west-2"
}

variable "s3_bucket_name" {
  default = "my-s3-bucket"
}

variable "notebook_instance_type" {
  default = "ml.t2.medium"
}

# Create a Security Group for the Notebook instance
resource "aws_security_group" "notebook_sg" {
  name_prefix = "my-notebook-sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an IAM role for the Notebook instance
resource "aws_iam_role" "notebook_role" {
  name = "my-notebook-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the IAM role
resource "aws_iam_policy" "notebook_policy" {
  name = "my-notebook-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Action = [
          "sagemaker:CreatePresignedNotebookInstanceUrl"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "notebook_policy_attachment" {
  policy_arn = aws_iam_policy.notebook_policy.arn
  role       = aws_iam_role.notebook_role.name
}

# Create a SageMaker Notebook instance
resource "aws_sagemaker_notebook_instance" "my_notebook" {
  name               = "my-notebook"
  role_arn           = aws_iam_role.notebook_role.arn
  instance_type      = var.notebook_instance_type
  subnet_id          = aws_subnet.private_subnet.id
  security_group_ids = [aws_security_group.notebook_sg.id]

  tags = {
    Name = "my-notebook"
  }
}

# Generate a presigned URL for the Notebook instance
data "aws_sagemaker_notebook_instance" "my_notebook_data" {
  name = aws_sagemaker_notebook_instance.my_notebook.name
}

locals {
  presigned_url = data.aws_sagemaker_notebook_instance.my_notebook_data.presigned_notebook_instance_url
}

# Output the presigned URL
output "presigned_url" {
  value = local.presigned_url
}
