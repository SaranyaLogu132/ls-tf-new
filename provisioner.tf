# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ls-pro-ec2_security_group"
  description = "Allow SSH and HTTP access"
  vpc_id      = "vpc-04182d0e1a42bddac"  # Ensure this VPC ID is correct

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access (Restrict in production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Fetch latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "ls-latest" # Replace with your actual key pair name
  subnet_id     = "subnet-0d8c52cc1bea2e510"

 
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php php-mysqli
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello World LS</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "LS-StandaloneEC2"
  }

  # ✅ Upload mysql-connection.php to EC2 instance
  provisioner "file" {
    source      = "mysql-connection.php"
    destination = "/tmp/mysql-connection.php"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./ls-latest.pem")  # Ensure this file exists in your Terraform directory
      host        = self.public_ip
    }
  }

  # ✅ Move the file to the correct directory and set permissions
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mysql-connection.php /var/www/html/mysql-connection.php",
      "sudo chown apache:apache /var/www/html/mysql-connection.php",
      "sudo chmod 644 /var/www/html/mysql-connection.php",
      "sudo systemctl restart httpd"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./ls-latest.pem")
      host        = self.public_ip
    }
  }
}

# Output the public IP
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}
