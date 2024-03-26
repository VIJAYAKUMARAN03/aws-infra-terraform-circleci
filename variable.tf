variable "region" {
  default = "ap-south-1"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "public_key" {
  default = "~/.ssh/bastion_key_dev.pub"
}

variable "private_key" {
  default = "~/.ssh/bastion_key_dev"
}

variable "amis" {
  type = map(string)
  default = {
    ap-south-1 = "ami-02a2af70a66af6dfb"
    us-east-1 = "ami-0759f51a90924c166"
  }
}
variable "environment" {
  default = "myenv"
}
variable "short_region_name" {
  default = "us1"
}

variable "prefix" {
  type    = string
  default = "centillion"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "test_lambda_function"
}
