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

resource "aws_iam_role_policy" "S3BucketPolicy" {
  name = "S3BucketPolicy"
  role = "${aws_iam_role.EC2InstanceToS3Role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::dimzul-week-2-bucket"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": ["arn:aws:s3:::dimzul-week-2-bucket/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role" "EC2InstanceToS3Role" {
    name = "EC2InstanceToS3Role"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "EC2InstanceToS3Profile" {
  name = "EC2InstanceToS3Profile"
  role = aws_iam_role.EC2InstanceToS3Role.name
}

resource "aws_security_group" "allow_ssh_and_tcp" {
  name        = "allow_ssh_and_tcp"
  description = "Allow SSH and TCP inbound traffic"

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
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "MyEC2Instance" {
  ami                     = "ami-0cf6f5c8a62fa5da6"
  instance_type           = var.ec2-instance-type
  key_name                = var.ec2-key-name
  iam_instance_profile    = "${aws_iam_instance_profile.EC2InstanceToS3Profile.id}"
  security_groups         = ["${aws_security_group.allow_ssh_and_tcp.name}"]
  user_data               = <<EOF
                            #!/bin/bash
                            aws s3 cp s3://dimzul-week-2-bucket/week-2/text.txt /home/ec2-user/text.txt
                            echo 'Downloaded' >> /home/ec2-user/done.txt
                            EOF
}
