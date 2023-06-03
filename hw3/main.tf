terraform {
  cloud {
    organization = "ihor-organization"
    workspaces {
      name = "learn-tfc-aws"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

data "aws_s3_bucket" "mybucket" {
  bucket = "my-first-bucket-ihor1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

output "my_bucket_name" {
  value = data.aws_s3_bucket.mybucket.bucket
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "my-first-bucket-ihor2"
}

resource "aws_iam_policy" "s3_policy" {
  name        = "s3_policy"
  description = "Policy for S3 access"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "dynamodb:PutItem"
      ],
      "Resource": [
        "arn:aws:s3:::my-first-bucket-ihor2",
        "arn:aws:s3:::my-first-bucket-ihor2/*",
        "arn:aws:dynamodb:us-west-2:646632584624:table/my-table"
      ]
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "terraform_function_role" {
  name               = "terraform_function_role"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = aws_iam_role.terraform_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_kinesis_stream" "event_stream" {
  name             = "event_stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Name = "event_stream"
  }
}

resource "aws_lambda_function" "terraform_function" {
  filename      = "lambda_function.zip"
  function_name = "pythonFunction1"
  handler       = "index.handler"
  role          = aws_iam_role.terraform_function_role.arn
  runtime       = "python3.10"
  timeout       = 10

  environment {
    variables = {
      EVENT_STREAM_NAME = aws_kinesis_stream.event_stream.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "kinesis_mapping" {
  event_source_arn = aws_kinesis_stream.event_stream.arn
  function_name    = aws_lambda_function.terraform_function.arn
  starting_position = "LATEST"
}

resource "aws_lambda_function" "http_function" {
  filename      = "lambda_function.zip"
  function_name = "pythonFunction2"  # Unique name for the new Lambda function
  handler       = "index.handler"
  role          = aws_iam_role.terraform_function_role.arn
  runtime       = "python3.10"
  timeout       = 10

  environment {
    variables = {
      EVENT_STREAM_NAME = aws_kinesis_stream.event_stream.name
    }
  }

}

resource "aws_dynamodb_table" "my_table" {
  name           = "my-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}
