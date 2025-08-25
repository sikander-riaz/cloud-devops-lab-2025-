provider "aws" {
  region  = "ap-south-1"
  profile = "tkxel"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project VPC"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"  # Change as needed
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}


resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"  # Change as needed
  tags = {
    Name = "private_subnet"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}



resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}



resource "my_vpc" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
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


resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.my_vpc.id
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }
}



resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.my_vpc.id
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



output "vpc_id" {
  value = aws_vpc.my_vpc.id
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

# Create an EC2 instance
resource "aws_instance" "bastion" {
  ami           = "bastion" # Amazon Linux 2 AMI
  instance_type = "t2.micro"              # Adjust instance type as needed

  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.example_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 20 # Adjust volume size as needed
  }

  key_name = "keys.pem" # Replace with your existing key pair name or create a new one

  tags = {
    Name = "ExampleInstance"
  }
}




# Create an EC2 instance
resource "aws_instance" "application" {
  ami           = "ubuntu" # Amazon Linux 2 AMI
  instance_type = "t2.micro"              # Adjust instance type as needed

  subnet_id                   = aws_subnet.private-subnet.id
  vpc_security_group_ids      = [aws_security_group.example_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 50 # Adjust volume size as needed
  }

  key_name = "keys" # Replace with your existing key pair name or create a new one

  tags = {
    Name = "ExampleInstance"
  }
}





