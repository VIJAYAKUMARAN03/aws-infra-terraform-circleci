provider "aws" {
  region = var.region
}


#VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}


#PUBLIC SUBNET
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MySubnet"
  }
}

#SECURITY GROUP
resource "aws_security_group" "my_security_group" {
  name        = "MySecurityGroup"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#ENDPOINT
resource "aws_vpc_endpoint" "api_gateway_vpc_endpoint" {
  count = 3

  private_dns_enabled = false
  security_group_ids  = [aws_security_group.my_security_group.id]
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.my_vpc.id
  subnet_ids = [aws_subnet.my_subnet.id]
  tags = {
    Name = "api-gateway-vpc-endpoint"
  }
}

#API GATEWAY - RESTAPI
resource "aws_api_gateway_rest_api" "rest_api" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  name              = "api-gateway-name"
  put_rest_api_mode = "merge"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway_vpc_endpoint[0].id, aws_vpc_endpoint.api_gateway_vpc_endpoint[1].id, aws_vpc_endpoint.api_gateway_vpc_endpoint[2].id]
  }
}


#EC2
resource "aws_instance" "zoro-bastion-host" {
  ami = var.amis[var.region]
  key_name                    = aws_key_pair.bastion_key.key_name
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.my_security_group.id]
  subnet_id                   = aws_subnet.my_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "bastion-host-${var.environment}"
  }
}



#Glue
data "aws_iam_policy_document" "glue_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "glue_service_role" {
  name               = "${var.prefix}-glue-service-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.glue_policy_document.json
}

resource "aws_iam_role_policy_attachment" "glue_service_role_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_job" "blogpost_job" {
  name              = "${var.prefix}-job-${var.environment}"
  role_arn          = aws_iam_role.glue_service_role.arn
  glue_version      = "3.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = "1"
  timeout           = 2880
  command {
    name            = "glueetl"
    script_location = "./job.py"
  }
  default_arguments = {
    "--enable-auto-scaling"              = "true"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}




#Lambda

resource "aws_iam_role" "lambda_role" {
  name               = "terraform_aws_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/hello-python.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "./python/hello-python.zip"
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello-python.lambda_handler"
  runtime       = "python3.11"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}


#s3
resource "aws_s3_bucket" "test-bucket" {
  bucket = "bucket-learn-terraform-centillion-s3"

  tags = {
    Name        = "TF test bucket"
    Environment = "Dev"
  }
}
