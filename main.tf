#creates VPC, one public subnet, two private subnets, one EC2 instance and one MYSQL RDS instance
#declare variables
variable "access_key" {
default = "<Access_key>"
}
variable "secret_key" {
default = "<Private-Key>"
}
variable "region" {
default = "ap-southeast-1"
}
variable "vpc_cidr" {
default = "10.0.0.0/16"
}
variable "subnet_one_cidr" {
default = "10.0.1.0/24"
}
variable "subnet_two_cidr" {
default = ["10.0.2.0/24","10.0.3.0/24"]
}
variable "route_table_cidr" {
default = "0.0.0.0/0"
}
variable "web_ports" {
default = ["22","80", "443", "3306"]
}
variable "db_ports" {
default = ["22", "3306"]
}
variable "images" {
default = "ami-0fe1ff5007e7820fd"
}

#aws provider
provider "aws" {
access_key = "${var.access_key}"
secret_key = "${var.secret_key}"
region = "${var.region}"
}
#get AZ's details
data "aws_availability_zones" "availability_zones" {}
#create VPC
resource "aws_vpc" "myvpc" {
cidr_block = "${var.vpc_cidr}"
enable_dns_hostnames = true
tags = {
Name = "myvpc"
}
}
#create public subnet
resource "aws_subnet" "myvpc_public_subnet" {
vpc_id = "${aws_vpc.myvpc.id}"
cidr_block = "${var.subnet_one_cidr}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
map_public_ip_on_launch = true
tags = {
   Name = "myvpc_public_subnet"
  }
}
#create private subnet one
resource "aws_subnet" "myvpc_private_subnet_one" {
vpc_id = "${aws_vpc.myvpc.id}"
cidr_block = "${element(var.subnet_two_cidr, 0)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
tags = {
   Name = "myvpc_private_subnet_one"
  }
}
#create private subnet two
resource "aws_subnet" "myvpc_private_subnet_two" {
vpc_id = "${aws_vpc.myvpc.id}"
cidr_block = "${element(var.subnet_two_cidr, 1)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[1]}"
tags = {
   Name = "myvpc_private_subnet_two"
  }
}
#create internet gateway
resource "aws_internet_gateway" "myvpc_internet_gateway" {
vpc_id = "${aws_vpc.myvpc.id}"
tags = {
Name = "myvpc_internet_gateway"
}
}
#create public route table (assosiated with internet gateway)
resource "aws_route_table" "myvpc_public_subnet_route_table" {
vpc_id = "${aws_vpc.myvpc.id}"
route {
cidr_block = "${var.route_table_cidr}"
gateway_id = "${aws_internet_gateway.myvpc_internet_gateway.id}"
}
tags = {
Name = "myvpc_public_subnet_route_table"
}
}
#create private subnet route table
resource "aws_route_table" "myvpc_private_subnet_route_table" {
vpc_id = "${aws_vpc.myvpc.id}"
tags = {
Name = "myvpc_private_subnet_route_table"
}
}
#create default route table
resource "aws_default_route_table" "myvpc_main_route_table" {
default_route_table_id = "${aws_vpc.myvpc.default_route_table_id}"
tags  = {
Name = "myvpc_main_route_table"
}
}
#assosiate public subnet with public route table
resource "aws_route_table_association" "myvpc_public_subnet_route_table" {
subnet_id = "${aws_subnet.myvpc_public_subnet.id}"
route_table_id = "${aws_route_table.myvpc_public_subnet_route_table.id}"
}
#assosiate private subnets with private route table
resource "aws_route_table_association" "myvpc_private_subnet_one_route_table_assosiation" {
subnet_id = "${aws_subnet.myvpc_private_subnet_one.id}"
route_table_id = "${aws_route_table.myvpc_private_subnet_route_table.id}"
}
resource "aws_route_table_association" "myvpc_private_subnet_two_route_table_assosiation" {
subnet_id = "${aws_subnet.myvpc_private_subnet_two.id}"
route_table_id = "${aws_route_table.myvpc_private_subnet_route_table.id}"
}
#create security group for web
resource "aws_security_group" "web_security_group" {
name = "web_security_group"
description = "Allow all inbound traffic"
vpc_id = "${aws_vpc.myvpc.id}"
tags = {
Name = "myvpc_web_security_group"
}
}
#create security group ingress rule for web
resource "aws_security_group_rule" "web_ingress" {
count = "${length(var.web_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web_security_group.id}"
}
#create security group egress rule for web
resource "aws_security_group_rule" "web_egress" {
count = "${length(var.web_ports)}"
type = "egress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web_security_group.id}"
}
#create security group for db
resource "aws_security_group" "db_security_group" {
name = "db_security_group"
description = "Allow all inbound traffic"
vpc_id = "${aws_vpc.myvpc.id}"
tags = {
Name = "myvpc_db_security_group"
}
}
#create security group ingress rule for db
resource "aws_security_group_rule" "db_ingress" {
count = "${length(var.db_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.db_ports, count.index)}"
to_port = "${element(var.db_ports, count.index)}"
security_group_id = "${aws_security_group.db_security_group.id}"
}
#create security group egress rule for db
resource "aws_security_group_rule" "db_egress" {
count = "${length(var.db_ports)}"
type = "egress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.db_ports, count.index)}"
to_port = "${element(var.db_ports, count.index)}"
security_group_id = "${aws_security_group.db_security_group.id}"
}

#create EC2 instance
resource "aws_instance" "my_web_instance" {
ami = "ami-0fe1ff5007e7820fd"
instance_type = "t2.micro"
key_name = "nn-terraform" 
vpc_security_group_ids = ["${aws_security_group.web_security_group.id}"]
subnet_id = "${aws_subnet.myvpc_public_subnet.id}"
user_data = "${file("install_apache.sh")}"
tags = {
	Name = "my_web_instance"
}
}
