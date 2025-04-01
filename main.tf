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

locals { 
    image = "ghcr.io/csse6400/taskoverflow:latest" 
    database_username = "administrator" 
    database_password = "foobarbaz" # This is bad! 
}

data "aws_iam_role" "lab" { 
   name = "LabRole" 
} 
 
data "aws_vpc" "default" { 
   default = true 
} 
 
data "aws_subnets" "private" { 
   filter { 
      name = "vpc-id" 
      values = [data.aws_vpc.default.id] 
   } 
}

resource "aws_ecs_cluster" "taskoverflow" { 
   name = "taskoverflow" 
}
 
resource "aws_db_instance" "taskoverflow_database" { 
    allocated_storage = 20 
    max_allocated_storage = 1000 
    engine = "postgres" 
    engine_version = "17" 
    instance_class = "db.t3.micro" 
    db_name = "todo" 
    username = local.database_username 
    password = local.database_password 
    parameter_group_name = "default.postgres17" 
    skip_final_snapshot = true 
    vpc_security_group_ids = [aws_security_group.taskoverflow_database.id] 
    publicly_accessible = true 
 
    tags = { 
        Name = "taskoverflow_database" 
    } 
}

resource "aws_security_group" "taskoverflow_database" { 
    name = "taskoverflow_database" 
    description = "Allow inbound Postgresql traffic" 
 
    ingress { 
        from_port = 5432 
        to_port = 5432 
        protocol = "tcp" 
        cidr_blocks = ["0.0.0.0/0"] 
    } 
 
    egress { 
        from_port = 0 
        to_port = 0 
        protocol = "-1" 
        cidr_blocks = ["0.0.0.0/0"] 
        ipv6_cidr_blocks = ["::/0"] 
    } 
 
    tags = { 
        Name = "taskoverflow_database" 
    } 
}

