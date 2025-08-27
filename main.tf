provider "aws" {
  region  = "ap-south-1"
  profile = "tkxel"
}

# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "VPC-one"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

# Private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private_subnet"
  }
}

# Internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW"
  }
}

# Public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

# Private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private_route_table"
  }
}

# NAT gateway setup
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my_igw]
  tags = {
    Name = "NAT EIP"
  }
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.my_igw]
  tags = {
    Name = "my_nat_gateway"
  }
}

# Private route
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}

# Route associations
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# ---------------- Security Groups ----------------
resource "aws_security_group" "public_sg" {
  name_prefix = "public-sg-"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "public_sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  name_prefix = "private-sg-"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "private_sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
}

# ---------------- AMI ----------------
variable "AmiLinux" {
  type = map(string)
  default = {
    ap-south-1 = "ami-02d26659fd82cf299"
  }
}

variable "region" {
  default = "ap-south-1"
}

# ---------------- SSH Key ----------------
# Generate SSH private key
resource "tls_private_key" "auth_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key with AWS
resource "aws_key_pair" "auth_key" {
  key_name   = "auth"
  public_key = tls_private_key.auth_key.public_key_openssh
}

# Save the private key locally in ~/.ssh/auth.pem
resource "local_file" "private_key" {
  content         = tls_private_key.auth_key.private_key_pem
  filename        = pathexpand("~/.ssh/auth.pem")
  file_permission = "0600"
}

# ---------------- EC2 Instances ----------------
resource "aws_instance" "bastion" {
  ami                         = lookup(var.AmiLinux, var.region)
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.auth_key.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_instance" "application" {
  ami                         = lookup(var.AmiLinux, var.region)
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.auth_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  tags = {
    Name = "AppServer"
  }
}

# ---------------- Ansible Inventory ----------------
variable "ssh_key" {
  description = "SSH private key filename"
  type        = string
  default     = "auth"
}


resource "local_file" "ansible_inventory" {
  filename = "${path.module}/hosts.ini"

  content = <<EOT
[bastion]
${aws_instance.bastion.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ruben/.ssh/auth.pem

[appserver]
${aws_instance.application.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ruben/.ssh/auth.pem ansible_ssh_common_args="-o ProxyCommand=\"ssh -W %h:%p -q ubuntu@${aws_instance.bastion.public_ip} -i /home/ruben/.ssh/auth.pem\""
EOT
}


# ---------------- Terraform State Backend ----------------
resource "aws_s3_bucket" "tfstatebucket" {
  bucket = "siku-tfstate-bucket"
}

resource "aws_s3_bucket_versioning" "tfstatebucket_versioning" {
  bucket = aws_s3_bucket.tfstatebucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_state_table" {
  name         = "tf_state_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ---------------- IAM Role for EC2 ----------------
variable "name" {
  type    = string
  default = "ec2-role"
}

resource "aws_iam_role" "ec2_role" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_monitoring_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ---------------- CloudWatch ----------------
variable "log_group_name" {
  description = "The name of the CloudWatch log group"
  type        = string
  default     = "sikander-log-group"
}

variable "retention_days" {
  description = "The number of days to retain the logs in the CloudWatch log group"
  type        = number
  default     = 7
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.log_group_name
  retention_in_days = var.retention_days
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "sikander-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}

# ---------------- Outputs ----------------
output "application_private_ip" {
  value = aws_instance.application.private_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.my_nat_gateway.id
}

output "BastionHost" {
  value = aws_instance.bastion.public_ip
}

output "applicationHost" {
  value = aws_instance.application.private_ip
}

output "ssh_key_name" {
  value = aws_key_pair.auth_key.key_name
}

output "public_sg_id" {
  value = aws_security_group.public_sg.id
}

output "private_sg_id" {
  value = aws_security_group.private_sg.id
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
}


resource "null_resource" "store_key_in_vault" {
  provisioner "local-exec" {
    command = <<EOT
      ansible-vault encrypt_string --stdin-name 'vault_ssh_private_key' < ~/.ssh/auth.pem > vault_key.yml
    EOT
  }
}
