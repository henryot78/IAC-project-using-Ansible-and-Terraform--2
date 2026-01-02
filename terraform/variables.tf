variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Existing EC2 key pair name in AWS"
  type        = string
  default     = "Onyekeypair"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH (port 22). Use YOUR_PUBLIC_IP/32 for best security."
  type        = string
  default     = "104.5.63.80/32"
}

variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "cloud-challenge-3"
}
