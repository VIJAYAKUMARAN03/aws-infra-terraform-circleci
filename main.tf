provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "tf-states" //your tfstate bucket name 
    key    = "dev.tfstate"
    region = "ap-south-1"
  }
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_VPC"
  }
}

# Public subnet
resource "aws_subnet" "subnet-1"{
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "my_public_subnet"
  }
} 


# internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-internet-gateway"
  }
}


# Route table
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "pubrt-route-table"
    environment = "${var.environment}"
  }
}

#Route table association
resource "aws_route_table_association" "public-subnet-route" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.public-route.id
  depends_on = [ aws_route_table.public-route ]
}

# Default Security Group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.my_vpc.id
}

#Security group for EC2
resource "aws_security_group" "sg-pub" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "security-group"
  description = "Security group that allows HTTPS ingress traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Currently it allow all ips. If you wnat only specific ip include the particular with /32 (ex: 18.24.3.50/32) at the end.
  }

  tags = {
    Name        = "sg-ec2-01"
    environment = "${var.environment}"
  }
}


# EC2 instance
resource "aws_instance" "ec2_instance" {
    ami = var.amis[var.region]
    instance_type = "${var.instance_type}"
    subnet_id = aws_subnet.subnet-1.id
    vpc_security_group_ids      = [aws_security_group.sg-pub.id]
    tags = {
      Name = "sample_ec2_instance"
      environment = "${var.environment}"
    }
}

# s3 Endpoint
resource "aws_vpc_endpoint" "s3-endpoint" {
  vpc_id            = aws_vpc.my_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "my-s3-endpoint"
    environment = "${var.environment}"
  }
}

# S3-bucket
resource "aws_s3_bucket" "prv-s3-01" {
  bucket = "prvs3-bucket"

  tags = {
    Name = "prvs3-bucket"
    environment = "${var.environment}"
  }
}


#ENDPOINT
resource "aws_vpc_endpoint" "api_gateway_vpc_endpoint" {
  count = 3

  private_dns_enabled = false
  security_group_ids  = [aws_security_group.sg-pub.id]
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.my_vpc.id
  subnet_ids = [aws_subnet.subnet-1.id]
  tags = {
    Name = "api-gateway-vpc-endpoint"
    environment = "${var.environment}"
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

  name              = "My-api-gateway"
  put_rest_api_mode = "merge"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway_vpc_endpoint[0].id, aws_vpc_endpoint.api_gateway_vpc_endpoint[1].id, aws_vpc_endpoint.api_gateway_vpc_endpoint[2].id]
  }

  tags = {
    Name = "api-gateway"
    environment = "${var.environment}"
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
  name               = "My-${var.prefix}-glue-service-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.glue_policy_document.json
}

resource "aws_iam_role_policy_attachment" "glue_service_role_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_job" "glue_job" {
  name              = "My-${var.prefix}-job-${var.environment}"
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
  tags = {
    Name = "my-glue-job"
    environment = "${var.environment}"
  }
}




#Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "My-terraform_aws_lambda_role"
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

  name        = "My-aws_iam_policy_for_terraform_aws_lambda_role"
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
resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "./python/hello-python.zip"
  function_name = "My-${var.function_name}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello-python.lambda_handler"
  runtime       = "python3.11"
  
  vpc_config {
    subnet_ids         = [aws_subnet.subnet-1.id]
    security_group_ids = [aws_security_group.sg-pub.id]
  }
  tags = {
    Name = "my-lambda"
    environment = "${var.environment}"
  }
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

}
