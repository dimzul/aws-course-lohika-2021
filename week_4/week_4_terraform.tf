terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

# ===== NETWORK =====

resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
  tags          = {
    Name = "Main VPC"
  }
}

resource "aws_default_route_table" "vpc_main_default_route_table" {
  default_route_table_id = aws_vpc.vpc_main.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = aws_instance.ec2_public_nat.id
  }
  tags          = {
    Name = "Main VPC default route table"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags          = {
    Name = "Public subnet"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  tags          = {
    Name = "Private subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "Internet gateway"
  }
}

resource "aws_route_table" "subnet_public_route_table" {
  vpc_id        = aws_vpc.vpc_main.id

  route {
    cidr_block    = "0.0.0.0/0"
    gateway_id    = aws_internet_gateway.internet_gateway.id
  }

  tags          = {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "subnet_public_route_table_association" {
  subnet_id       = aws_subnet.subnet_public.id
  route_table_id  = aws_route_table.subnet_public_route_table.id
}

# ===== EC2 =====

resource "aws_security_group" "sg_ec2_public" {
  name        = "SG for public EC2"
  description = "Allow SSH and TCP inbound traffic"
  vpc_id      = aws_vpc.vpc_main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_public" {
  subnet_id                   = aws_subnet.subnet_public.id
  ami                         = "ami-0518bb0e75d3619ca"
  instance_type               = var.ec2-instance-type
  key_name                    = var.ec2-key-name
  vpc_security_group_ids      = ["${aws_security_group.sg_ec2_public.id}"]
  user_data                   = <<EOF
#!/bin/bash

sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd
sudo chkconfig httpd on
sudo cd /var/www/html
# sudo chmod 766 -R /var/www/html
# sudo chmod 777 /var/www/html -R
sudo echo "<html><h1>This is WebServer from public subnet</h1></html>" >> index.html
sudo cp /index.html /var/www/html/
EOF
  tags = {
    Name = "EC2 public"
  }
}


resource "aws_security_group" "sg_ec2_private" {
  name        = "SG for private EC2"
  description = "Allows SSH, TCP and ICMP inbound traffic for CIDR range"
  vpc_id      = aws_vpc.vpc_main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_private" {
  subnet_id                   = aws_subnet.subnet_private.id
  ami                         = "ami-0518bb0e75d3619ca"
  instance_type               = var.ec2-instance-type
  key_name                    = var.ec2-key-name
  vpc_security_group_ids      = ["${aws_security_group.sg_ec2_private.id}"]
  user_data                   = <<EOF
#!/bin/bash

sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd
sudo chkconfig httpd on
sudo cd /var/www/html
sudo echo "<html><h1>This is WebServer from private subnet</h1></html>" >> index.html
sudo cp /index.html /var/www/html/
EOF
  tags = {
    Name = "EC2 private"
  }
}

resource "aws_instance" "ec2_public_nat" {
  subnet_id                   = aws_subnet.subnet_public.id
  ami                         = "ami-0032ea5ae08aa27a2"
  instance_type               = var.ec2-instance-type
  key_name                    = var.ec2-key-name
  vpc_security_group_ids      = ["${aws_security_group.sg_ec2_public.id}"]
  source_dest_check           = false
  tags = {
    Name = "EC2 public NAT"
  }
}

# ===== LOAD BALANCER =====

resource "aws_lb" "application_load_balancer" {
  name                  = "Application-load-balancer"
  load_balancer_type    = "application"
  security_groups       = [ aws_security_group.sg_ec2_public.id ]
  subnets               = [ aws_subnet.subnet_public.id, aws_subnet.subnet_private.id ]
}

resource "aws_lb_target_group" "alb_target_group" {
  name                  = "ALB-target-group"
  port                  = 80
  protocol              = "HTTP"
  vpc_id                = aws_vpc.vpc_main.id
  target_type           = "instance"
  health_check          {
    port                  = 80
    protocol              = "HTTP"
    path                  = "/index.html"
  }
}

resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = aws_lb.application_load_balancer.arn  
  port              = 80
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    type             = "forward"  
  }
}

resource "aws_alb_target_group_attachment" "public_ec2_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_public.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "private_ec2_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_private.id
  port             = 80
}
