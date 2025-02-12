provider "aws" {
  region = "us-east-1"  # Change as needed
}

# --------------------------
# VPC
# --------------------------
resource "aws_vpc" "lsp_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lsp-vpc"
  }
}

# --------------------------
# Subnet
# --------------------------
resource "aws_subnet" "lsp_subnet" {
  vpc_id                  = aws_vpc.lsp_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "lsp-subnet"
  }
}

# --------------------------
# Internet Gateway
# --------------------------
resource "aws_internet_gateway" "lsp_igw" {
  vpc_id = aws_vpc.lsp_vpc.id

  tags = {
    Name = "lsp-igw"
  }
}

# --------------------------
# Route Table
# --------------------------
resource "aws_route_table" "lsp_route_table" {
  vpc_id = aws_vpc.lsp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lsp_igw.id
  }

  tags = {
    Name = "lsp-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "lsp_rt_assoc" {
  subnet_id      = aws_subnet.lsp_subnet.id
  route_table_id = aws_route_table.lsp_route_table.id
}

# --------------------------
# Security Group
# --------------------------
resource "aws_security_group" "lsp_web_sg" {
  vpc_id = aws_vpc.lsp_vpc.id

  # Allow HTTP (80) traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (22) traffic from anywhere (Change this for security)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lsp-web-sg"
  }
}

# --------------------------
# EC2 Instance (Web Server)
# --------------------------
resource "aws_instance" "lsp_web_server" {
  ami           = "ami-085ad6ae776d8f09c"  # Replace with the latest AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.lsp_subnet.id
  vpc_security_group_ids = [aws_security_group.lsp_web_sg.id]  

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, World! This is a Terraform-provisioned web server." > /var/www/html/index.html
              EOF

  tags = {
    Name = "lsp-web-server"
  }
}
