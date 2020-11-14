provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
  assume_role {
  role_arn = var.role_arn
  }
}

terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "eric-tf-state"
    key            = "tf-eric/networking/terraform.tfstate"
    dynamodb_table = "eric-tf-state-locks"
    encrypt        = true
  }
}

resource "aws_vpc" "application" {
    cidr_block = "10.0.0.0/16"
    tags = {
        application = "Challenge VPC"
    }
}

resource "aws_subnet" "application_private_subnet1" {
    vpc_id = aws_vpc.application.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.2.0/24"
    tags = {
	Name = "private_sub3"
    }
}

resource "aws_subnet" "application_private_subnet2" {
    vpc_id = aws_vpc.application.id
    availability_zone = "us-east-1b"
    cidr_block = "10.0.3.0/24"
    tags = {
        Name = "private_sub4"
    }
}

resource "aws_subnet" "application_public_subnet1" {
    vpc_id = aws_vpc.application.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.0.0/24"
    tags = {
	Name = "public_sub1"
    }
}

resource "aws_subnet" "application_public_subnet2" {
    vpc_id = aws_vpc.application.id
    availability_zone = "us-east-1b"
    cidr_block = "10.0.1.0/24"
    tags = {
        Name = "public_sub2"
    }
}

resource "aws_eip" "for_NAT" {
 //   subnet_id = "${aws_subnet.application_public_subnet1.id}"  
}

resource "aws_internet_gateway" "application_internet_gateway" {
    vpc_id = aws_vpc.application.id
   tags = {
        Name = "main_igw"
    }     
}

resource "aws_nat_gateway" "nat_gateway" {
    subnet_id = aws_subnet.application_public_subnet1.id
    allocation_id = aws_eip.for_NAT.id
    depends_on = [ aws_internet_gateway.application_internet_gateway ]
}

resource "aws_route_table" "igw1" {
	vpc_id = aws_vpc.application.id
	route {
	   cidr_block = "0.0.0.0/0"
           gateway_id = aws_internet_gateway.application_internet_gateway.id
	}
}

resource "aws_route_table_association" "one_with_igw1" {
   subnet_id = aws_subnet.application_public_subnet1.id
   route_table_id = aws_route_table.igw1.id
}

resource "aws_route_table" "igw2" {
    vpc_id = aws_vpc.application.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.application_internet_gateway.id
    }
}

resource "aws_route_table_association" "one_with_igw2" {
	subnet_id = aws_subnet.application_public_subnet2.id
	route_table_id = aws_route_table.igw2.id
}

resource "aws_route_table" "ngw1" {
    vpc_id = aws_vpc.application.id
    route {
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_nat_gateway.nat_gateway.id
    }
}

resource "aws_route_table_association" "one_with_nat" {
	subnet_id = aws_subnet.application_private_subnet1.id
	route_table_id = aws_route_table.ngw1.id
}

resource "aws_security_group" "allow_traffic" {
	name = "Allow SSH and HTTP"
	description = "Allow traffic to Apache"
	vpc_id = aws_vpc.application.id

	ingress {
		from_port = 22
		to_port = 22
		protocol = "TCP"
		cidr_blocks = ["0.0.0.0/0"]	
	}

	ingress {
		from_port = 80
		to_port = 80
		protocol = "TCP"
		cidr_blocks = ["0.0.0.0/0"]		
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_lb" "application_lb" {
	name = "alb"
	internal = false
	load_balancer_type = "application"
	subnets = ["${aws_subnet.application_public_subnet1.id}","${aws_subnet.application_public_subnet2.id}"]
#	subnets = ["${aws_subnet.application_private_subnet1.id}","${aws_subnet.application_private_subnet2.id}"]
	security_groups = ["${aws_security_group.allow_traffic.id}"]
	enable_deletion_protection = false
	tags = {
		Load_Balancer = "alb"
	}
}

resource "aws_instance" "apache" {
        ami = "ami-096fda3c22c1c990a"
        instance_type = "t2.micro"
        subnet_id = aws_subnet.application_private_subnet1.id
        security_groups = ["${aws_security_group.allow_traffic.id}"]
        key_name = "Eric"
        user_data = <<-EOF
                #!/bin/bash
                sudo yum -y install httpd
		sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
		sudo systemctl enable amazon-ssm-agent
		sudo systemctl start amazon-ssm-agent
                echo "<p>Private Apache WebServer on Sub3</p>" >> /var/www/html/index.html
                sudo systemctl enable httpd
                sudo systemctl start httpd
                EOF
}

resource "aws_instance" "plain" {
        ami = "ami-096fda3c22c1c990a"
        instance_type = "t2.micro"
        subnet_id = aws_subnet.application_public_subnet1.id
        security_groups = ["${aws_security_group.allow_traffic.id}"]
        key_name = "Eric"
        user_data = <<-EOF
                #!/bin/bash
                sudo yum -y install httpd
                sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
                sudo systemctl enable amazon-ssm-agent
                sudo systemctl start amazon-ssm-agent
                echo "<p>Public Apache WebServer on Sub1</p>" >> /var/www/html/index.html
                sudo systemctl enable httpd
                sudo systemctl start httpd
                EOF
}
