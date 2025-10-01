resource "aws_key_pair" "default" {
  key_name   = "multi-container-app-key"
  public_key = var.ssh_public_key
}

variable "ssh_public_key" {
  type = string
}

resource "aws_instance" "multi-container-app" {
  ami           = "ami-0360c520857e3138f" # Ubuntu 24.04
  instance_type = "t3.micro"
  key_name      = aws_key_pair.default.key_name

  tags = {
    Name = "multi-container-app-server"
  }

  security_groups = [aws_security_group.allow_http_ssh.name]
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
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