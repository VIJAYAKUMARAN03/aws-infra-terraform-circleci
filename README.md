# AWS Infrastructure Architecture with Terraform and CircleCI

This repository contains Terraform code to provision AWS infrastructure components including a VPC, subnet, security group, API Gateway, EC2 instance, AWS Glue job, AWS Lambda function, and an S3 bucket. Additionally, it includes CircleCI configuration for continuous integration and continuous deployment (CI/CD).

## Introduction

This project aims to automate the provisioning and management of AWS infrastructure using Terraform and CircleCI. By following the steps outlined in this guide, you'll be able to set up a seamless integration between Terraform and CircleCI, enabling you to deploy infrastructure changes automatically.

## Prerequisites

Before getting started, ensure you have the following:

- An AWS account with appropriate permissions to create and manage resources.
- Git installed on your local machine.
- Installed Terraform locally.
- AWS CLI configured with appropriate access credentials.
- Access to a CircleCI account with permissions to set up projects.
- A Git hosting service account (e.g., GitHub, GitLab) to host your Terraform code.
- A CircleCI account to set up continuous integration for your project.
- Important : Create a s3 bucket in AWS which is used to store the backend states of terraform.


## Getting Started

### Run the code in local

Follow the steps below to run the code in your local machine:

### Step 1: Clone the Repository

Clone the repository containing the Terraform code to your local environment and set it as your local repository.

```bash
git clone https://github.com/VIJAYAKUMARAN03/aws-infra-terraform-circleci.git
```

Navigate to the cloned directory:

```bash
cd aws-infra-terraform-circleci
```

### Step 2: Review the Variables:

Review and modify variables.tf to customize your AWS resources.

### Step 3: Initialize Terraform:

The terraform init command initializes a working directory containing Terraform configuration files.

```bash
terraform init
```

### Step 4: Terraform Plan:

Generates an execution plan showcasing what actions Terraform will take to modify infrastructure, without actually making any changes.

```bash
terraform plan
```

### Step 5: Terraform Apply:

Applies the changes specified in the Terraform configuration, creating or modifying infrastructure as defined.

```bash
terraform apply
```
The above command will first run the terraform plan and then it asks for approval from the user. Give "yes" in your CLI to continue the terraform apply process.

##### or

```bash
terraform apply --auto-approve
```
The above command will skips interactive approval of plan before applying. 

### Step 6: Validate Resource Creation:

Upon execution of the 'terraform apply' command, the specified resources will be provisioned within your AWS account. You can confirm the successful creation of these resources by accessing your AWS account and navigating to the corresponding resource sections.

### Step 7: Terraform Destroy:

Destroys all the resources defined in the Terraform configuration, effectively removing the infrastructure provisioned by Terraform.

```bash
terraform destroy
```
The above command will first run the terraform destroy plan and then it asks for approval from the user. Give "yes" in your CLI to continue the terraform destroy process.

##### or

```bash
terraform destroy --auto-approve
```
The above command will skips interactive approval of plan before destroying the resources. 

### Run the code using CircleCI CI/CD:

Follow the steps below to set up Terraform and CircleCI integration for managing AWS infrastructure:

### Step 1: Clone the Repository

Clone the repository containing the Terraform code to your local environment and set it as your local repository.

```bash
git clone https://github.com/VIJAYAKUMARAN03/aws-infra-terraform-circleci.git
```

Navigate to the cloned directory:

```bash
cd aws-infra-terraform-circleci
```

### Step 2 : Create a New Repository
Create a new repository in your Git hosting service to host your Terraform code.

### Step 3: Set up CircleCI
Create a CircleCI account and connect it with your Git account. Follow the prompts to integrate your repository with CircleCI, which will be shown as a project.
Link : https://circleci.com/vcs-authorize/

### Step 4: Configure Environment Variables
Set the following environment variables in CircleCI for the project:
- TF_VAR_access_key: AWS access key value
- TF_VAR_secret_key: AWS secret key value
- ENV: Choose from dev, prod, or qa to dynamically change Terraform configurations.
Note: Environment variable names are case-sensitive.
Refer : https://circleci.com/docs/set-environment-variable/

### Step 5: Pull Repository Changes
Pull the changes from your newly created repository.
```bash
git pull origin main
```

### Step 6: Add Files to Your Repository
Add the necessary files from the cloned repository to your newly created repository.
```bash
git add .
```

### Step 7: Verify Configuration Files
Check and verify the values of the variables in variables.tf file. Ensure to verify the instance_type values, especially.

### Step 8: Commit and Push Changes
Commit your changes with appropriate commit message.
```bash
git commit -m "Initial commit with Terraform files"
```

Push the commit to your repository.
```bash
git push origin main
```

After pushing changes, monitor the pipeline output in the CircleCI dashboard to ensure successful execution.

## CircleCI Configuration

This repository includes a CircleCI configuration file (config.yml) that automates the Terraform workflow

### Workflow

The CircleCI workflow automates the following steps:

#### Terraform Init:
- Initializes Terraform and prepares the environment.

#### Terraform Plan: 
- Generates an execution plan for the proposed infrastructure changes.

#### Terraform Apply & Output:
- Applies Terraform changes to create infrastructure and outputs the resources created.

#### Terraform Apply & Output:
- Waits for manual approval before proceeding to destroy the infrastructure.

#### Complete Infrastructure Hold:
- Destroys the provisioned infrastructure after manual approval.

## Thanks for reading, Have a nice day!
