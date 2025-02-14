provider "aws" {
  region = "us-east-1"  # Primary Region
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"  # Secondary Region
}

# Variables
variable "ami_id" {
  default = "ami-085ad6ae776d8f09c" # Amazon Linux 2
}

variable "instance_type" {
  default = "t2.micro"
}

variable "bucket_prefix" {
  default = "ls-multi-region-bucket"
}

# EC2 in Primary Region
resource "aws_instance" "primary_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "Primary-EC2"
  }
}

# EC2 in Secondary Region
resource "aws_instance" "secondary_ec2" {
  provider      = aws.secondary
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "LS-Secondary-EC2"
  }
}

# S3 Bucket in Primary Region
resource "aws_s3_bucket" "primary_bucket" {
  bucket = "${var.bucket_prefix}-us-east-1"
}

# S3 Bucket in Secondary Region
resource "aws_s3_bucket" "secondary_bucket" {
  provider = aws.secondary
  bucket   = "${var.bucket_prefix}-us-west-2"
}

# Output values
output "primary_ec2_public_ip" {
  value = aws_instance.primary_ec2.public_ip
}

output "secondary_ec2_public_ip" {
  value = aws_instance.secondary_ec2.public_ip
}

output "primary_s3_bucket" {
  value = aws_s3_bucket.primary_bucket.bucket
}

output "secondary_s3_bucket" {
  value = aws_s3_bucket.secondary_bucket.bucket
}
