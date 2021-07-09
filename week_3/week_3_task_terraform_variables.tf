variable "ec2-instance-type" {
  type    = string
  default = "t2.micro"
}

variable "ec2-key-name" {
	type = string
	default = "aws-course-2021"
}

variable "dynamodb-table-name" {
	type = string
	default = "dynamodb-table-student"
}

variable "rds-username" {
	type = string
	default = "rds_admin"
}

variable "rds-password" {
	type = string
	default = "rds_admin-pass-5"
}