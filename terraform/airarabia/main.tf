
# LOCALS
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

locals {
  public_ingress_rules = [
    {
      description = "SSH"
      port        = 22
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP"
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HAProxy Stats 8084"
      port        = 8084
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HAProxy Stats 8085"
      port        = 8085
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  private_ingress_rules = [
    {
      description = "SSH from HAProxy"
      port        = 22
    },
    {
      description = "HTTP from HAProxy"
      port        = 80
    }
  ]
}


# VPC


resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}


# INTERNET GATEWAY


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# SUBNETS


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-private-subnet-1"
    Type = "private"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.project_name}-private-subnet-2"
    Type = "private"
  }
}


# PUBLIC ROUTE TABLE


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}


# NAT GATEWAY


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}


# PRIVATE ROUTE TABLE


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private1_assoc" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private2_assoc" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}


# SECURITY GROUP - HAPROXY / BASTION


resource "aws_security_group" "haproxy_sg" {
  name        = "${var.project_name}-haproxy-sg"
  description = "HAProxy and Bastion Security Group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.public_ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-haproxy-sg"
  }
}


# SECURITY GROUP - APP SERVERS


resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Private Application Servers Security Group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.private_ingress_rules

    content {
      description     = ingress.value.description
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      protocol        = "tcp"
      security_groups = [aws_security_group.haproxy_sg.id]
    }
  }

  egress {
    description = "Allow all outbound traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}


# EC2 - HAPROXY / BASTION


resource "aws_instance" "haproxy" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.haproxy_sg.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.airarabia.key_name

  tags = {
    Name        = "${var.project_name}-haproxy"
    Role        = "haproxy-bastion"
    Environment = "production"
  }
}

# PUBLIC ELASTIC IP

resource "aws_eip" "haproxy_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-haproxy-eip"
  }
}

resource "aws_eip_association" "haproxy_eip_assoc" {
  instance_id   = aws_instance.haproxy.id
  allocation_id = aws_eip.haproxy_eip.id
}



# SSH KEYS

resource "aws_key_pair" "airarabia" {
  key_name   = "airarabia"
  public_key = file("~/.ssh/id_ed25519.pub")

  tags = {
    Name = "airarabia-key"
  }
}


# EC2 - APP SERVERS


resource "aws_instance" "app_servers" {
  for_each = {
    web01 = aws_subnet.private1.id
    web02 = aws_subnet.private2.id
  }




  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = aws_key_pair.airarabia.key_name

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Role        = "application"
    Environment = "production"
  }
}

# GENERATE ANSIBLE INVENTORY


resource "local_file" "ansible_inventory" {

  filename = "../../ansible/inventories/airarabia/hosts.ini"

  content = templatefile("${path.module}/inventory.tpl", {

    haproxy_public_ip = aws_eip.haproxy_eip.public_ip

    web01_private_ip = aws_instance.app_servers["web01"].private_ip

    web02_private_ip = aws_instance.app_servers["web02"].private_ip

    haproxy_frontend_port  = 80
    haproxy_stats_port     = 8404
    haproxy_stats_uri      = "/stats"
    haproxy_stats_user     = "admin"
    haproxy_stats_password = "admin@123"
  })
}
