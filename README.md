 # Overview

This project demonstrates how to provision and configure AWS infrastructure using a modern Infrastructure as Code (IaC) workflow.
Instead of manually clicking around the AWS Console, the entire environment is:
Provisioned automatically with Terraform (infrastructure)
Configured automatically with Ansible (server setup)
The result is a reproducible cloud deployment that can be rebuilt from scratch consistently, making it ideal for real-world DevOps teams and scalable cloud operations.
# The goal is to improve:
* Repeatability 🔁
* Speed of deployment ⚡
* Security (least exposure) 🔐
* Maintainability 🛠️
* Infrastructure consistency 🧱



---

## Project Architecture (High Level)


```
project-root/
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini
│   └── playbook.yml
└── README.md
```

## What This Project Simulates
* In a real enterprise environment, this project represents:
* Automating cloud infrastructure provisioning (instead of manual setup)
* Building infrastructure in a reusable, version-controlled way
* Separating responsibilities between:
* Infrastructure provisioning (Terraform)
* Configuration management (Ansible)
# Following DevOps best practices such as:
* SSH locked to my IP (YOUR_PUBLIC_IP/32)
* IAM roles instead of hardcoded credentials
* Git hygiene (no .terraform or binaries committed)

## Terraform Configuration

### terraform/versions.tf
```hcl
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}
```

### terraform/variables.tf
```hcl
variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "Onyekeypair"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ssh_cidr" {
  default = "104.5.63.80/32"
}

variable "project_name" {
  default = "cloud-challenge-3"
}
```

### terraform/main.tf
```hcl
provider "aws" {
  region = var.region
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project_name}-${random_id.suffix.hex}"
}

resource "aws_security_group" "web_sg" {
  name   = "${var.project_name}-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "HelloWorldServer"
  }
}
```

### terraform/outputs.tf
```hcl
output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}
```

---

## Running Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Type **yes** when prompted.

You will see:
- EC2 public IP
- Web URL

Copy the **public IP** for Ansible.

---

## SSH Key Check

```bash
ls -l ~/Downloads/Onyekeypair.pem
chmod 400 ~/Downloads/Onyekeypair.pem
```

---

## SSH Test

```bash
ssh -i ~/Downloads/Onyekeypair.pem ubuntu@<EC2_PUBLIC_IP>
```

Type **yes** if prompted.  
Exit with:

```bash
exit
```

---

## Ansible Setup


## ansible/ansible.cfg
```bash
[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False
```

### ansible/inventory.ini
```ini
[web]
<EC2_PUBLIC_IP> ansible_user=ubuntu
```
## ansible/playbook.yml
```bash
- name: Configure web server and deploy Hello World
  hosts: web
  become: true

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Create Hello World page
      copy:
        dest: /var/www/html/index.html
        content: |
          <html>
            <head><title>Hello</title></head>
            <body style="font-family: Arial;">
              <h1>Hello, World!</h1>
              <p>Deployed by Ansible ✅</p>
            </body>
          </html>

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
        enabled: true
```

## Run Ansible

### Ping Test
```bash
cd ansible
ansible -i inventory.ini web -m ping --private-key ~/Downloads/Onyekeypair.pem
```

Expected:
```
SUCCESS => ping: pong
```

### Run Playbook
```bash
ansible-playbook -i inventory.ini playbook.yml --private-key ~/Downloads/Onyekeypair.pem
```

---

## Verify Website

Open in browser:
```
http://<EC2_PUBLIC_IP>
```

Or via terminal:
```bash
curl http://<EC2_PUBLIC_IP>
```

You should see **Hello, World!**

---

## Cleanup 

```bash
cd terraform
terraform destroy
```

Type **yes**.

---

## Done ✅

## Outcome: 
- Built infrastructure with Terraform
- Configured a server with Ansible
- Deployed a live web page on AWS
