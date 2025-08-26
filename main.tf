provider "aws" {
  region  = "ap-south-1"
  profile = "tkxel"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Project VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW"
  }
}

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

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private_route_table"
  }
}

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

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

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

variable "AmiLinux" {
  type = map(string)
  default = {
    ap-south-1 = "ami-02d26659fd82cf299"
  }
}




variable "region" {
  default = "ap-south-1"
}


variable "key_name" {
  default     = "sik"
  description = "the ssh key to use in the EC2 machines"
}
resource "aws_instance" "bastion" {
  ami                         = lookup(var.AmiLinux, var.region)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "BastionHost"
  }
  user_data = <<-EOF

  #!/bin/bash
   set -e
  sudo apt update 
  sudo apt upgrade -y
  sudo apt install ansible -y
  EOF

}


resource "aws_instance" "application" {
  ami                         = lookup(var.AmiLinux, var.region)
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  tags = {
    Name = "AppServer"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y

  
  sudo apt install -y ansible

  ansible —version
EOF

}

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





# tf bucket and dynamo db
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











output "BastionHost" {
  value = aws_instance.bastion.public_ip
}

output "applicationHost" {
  value = aws_instance.application.private_ip
}


output "ssh_key_name" {
  value = var.key_name
}

output "public_sg_id" {
  value = aws_security_group.public_sg.id
}


output "private_sg_id" {
  value = aws_security_group.private_sg.id
}



# resource "local_file" "ansible_inventory" {
#   filename = "${path.module}/inventory.ini"

#   content = templatefile("${path.module}/inventory.tmpl", {
#     bastion_ip = aws_instance.bastion.public_ip
#     app_ip     = aws_instance.application.private_ip
#     ssh_key    = var.key_name
#   })
# }



variable "app_ip" {
  description = "Private IP of the application server"
  type        = string
}
variable "ssh_key" {
  description = "SSH private key filename (without path)"
  type        = string
  default     = "sik.pem"
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/hosts.ini"

  content = <<-EOT
    [appservers]
    ${aws_instance.application.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.ssh_key} ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@${aws_instance.bastion.public_ip} -i ~/.ssh/${var.ssh_key}"'
  EOT
}
