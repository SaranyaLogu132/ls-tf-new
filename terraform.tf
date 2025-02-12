provider "aws" {
  region     = "us-east-1"
}

resource "aws_s3_bucket" "my-bucket" {
  bucket = "ls-bucket-terraform" 
  acl    = "private" 

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Dev"
  }
}
