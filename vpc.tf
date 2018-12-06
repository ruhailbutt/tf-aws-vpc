resource "aws_vpc" "Dev" {
 cidr_block = "${var.vpc_cidr}"
# instance_tenancy = "${var.instance_tenancy}"
 enable_dns_hostnames = "${var.enable_dns_hostnames}"
 enable_dns_support = "${var.enable_dns_support}"
 #vpc_region = "${var.vpc_region}"

 
 tags {
 Name= "${var.vpc_name}"
 }
}

/*
Internet Gateway..
*/
resource "aws_internet_gateway" "igw" {
 vpc_id = "${aws_vpc.Dev.id}"
 
 tags {
 Name = "IGW"
}
}
/*
Public Route Table..
*/
resource "aws_route_table" "Public-route" {
 vpc_id = "${aws_vpc.Dev.id}"
 route {
 cidr_block = "0.0.0.0/0"
 gateway_id = "${aws_internet_gateway.igw.id}"
}

tags {
 Name = "Pub_Route"
 }
}
resource "aws_route_table_association" "route_table_association_pub_sn" {
 subnet_id = "${aws_subnet.us-east-1a-pub-sn.id}"
 route_table_id = "${aws_route_table.Public-route.id}"
 }
/*
Elastic IP
*/
resource "aws_eip" "eip-nat-gw" {
 vpc ="true"
 tags {
 Name = "NAT-EIP"
}

}
/*
NAT Gateway..
*/
resource "aws_nat_gateway" "nat-gw" {
 allocation_id = "${aws_eip.eip-nat-gw.id}"
 subnet_id = "${aws_subnet.us-east-1a-pub-sn.id}"
 depends_on = ["aws_internet_gateway.igw"]

 tags {
 Name = "NAT-GW"
}
}
/*
Private Route Table
*/
resource "aws_route_table" "private_route_table" {
 vpc_id = "${aws_vpc.Dev.id}"
 
 tags {
 Name = "Private route table"
 }
}
 resource "aws_route" "private_route" {
 route_table_id = "${aws_route_table.private_route_table.id}"
 destination_cidr_block = "0.0.0.0/0"
 nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
} 
resource "aws_route_table_association" "us-east-1b-pri-sn_association"  {
 subnet_id = "${aws_subnet.us-east-1b-pri-sn.id}"
 route_table_id = "${aws_route_table.private_route_table.id}"
}
/*
Public subnet
*/
resource "aws_subnet" "us-east-1a-pub-sn" {
 vpc_id = "${aws_vpc.Dev.id}"
 cidr_block = "${var.pub_subnet_cidr}"
 availability_zone = "${var.pub_subnet_az}"
 map_public_ip_on_launch = "${var.pub_subnet_ip_on_launch}"

 tags = {
  Name = "Public Subnet-us-east1-a"
 }
}
/*
Private subnet..
*/
resource "aws_subnet" "us-east-1b-pri-sn" {
 vpc_id = "${aws_vpc.Dev.id}"
 cidr_block = "${var.pri_subnet_cidr}"
 availability_zone = "${var.pri_subnet_az}"

 tags = {
  Name = "Private Subnet-us-east1-b"
 }
}
/*
Security groups..
*/
resource "aws_security_group" "Public-sg" {
 name = "public_sg"
 description = "Allow all in bound traffic"
 vpc_id = "${aws_vpc.Dev.id}"
 
 ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
 from_port = 22
 to_port = 22
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
}
ingress {
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
}
 egress {
 from_port = 80
 to_port = 80
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
}

egress {
 from_port = 22
 to_port = 22
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
}
egress {
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]

 }
 tags {
 Name = "Public SG"
}
}
resource "aws_security_group" "Private-sg" {
 name = "private_sg"
 description = "Allow ssh from the public subnet only"
 vpc_id = "${aws_vpc.Dev.id}"
 
  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
#  cidr_blocks = ["${var.pub_subnet_cidr}"]
  security_groups = ["${aws_security_group.Public-sg.id}"]
}
 ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
#  cidr_blocks = ["${var.pub_subnet_cidr}"]
   security_groups = ["${aws_security_group.Public-sg.id}"]
}
 ingress {
  from_port = 443
  to_port = 443
  protocol = "tcp"
# cidr_blocks = ["${var.pub_subnet_cidr}"]
  security_groups = ["${aws_security_group.Public-sg.id}"]
 }
 tags {
 Name = "Private SG"
}
}

resource "aws_instance" "webserver" {
 ami = "${lookup(var.amis,var.region)}"
 count = 1
 key_name = "${var.key}"
 vpc_security_group_ids  = ["${aws_security_group.Public-sg.id}"]
 instance_type = "${var.instance_type}"
 subnet_id = "${aws_subnet.us-east-1a-pub-sn.id}"
 tags {
  Name = "web-server-${count.index+1}"
}
}

resource "aws_instance" "db-server" {
 ami = "${lookup(var.amis,var.region)}"
 count = 1
 key_name = "${var.key}"
 vpc_security_group_ids  = ["${aws_security_group.Private-sg.id}"]
 instance_type = "${var.instance_type}"
 subnet_id = "${aws_subnet.us-east-1b-pri-sn.id}"
 tags {
  Name = "db-server-${count.index+1}"
}
}
