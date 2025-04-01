terraform { 
   required_providers { 
      aws = { 
         source = "hashicorp/aws" 
         version = "~> 5.0" 
      } 
   } 
} 
 
provider "aws" { 
   region = "us-east-1" 
   shared_credentials_files = ["./credentials"] 
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Security group for RDS
resource "aws_security_group" "todogroup" {
  name        = "todogroup"
  description = "Security group for todo RDS instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todogroup"
  }
}

# RDS instance
resource "aws_db_instance" "todo" {
  identifier           = "todo"
  engine              = "postgres"
  engine_version      = "17"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  
  db_name             = "todo"
  username           = "todoadmin"
  password           = "Todoadmin123$"
  
  skip_final_snapshot = true
  publicly_accessible = true
  
  vpc_security_group_ids = [aws_security_group.todogroup.id]
  db_subnet_group_name   = aws_db_subnet_group.todo.name

  tags = {
    Name = "todo"
  }
}

# DB subnet group
resource "aws_db_subnet_group" "todo" {
  name       = "todo-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "todo-subnet-group"
  }
}