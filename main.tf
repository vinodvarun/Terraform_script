#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = {
    Name  = "${var.vpc_name}"
    Owner = "ssvkart5"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags = {
    Name = "${var.IGW_name}"
  }
}

resource "aws_subnet" "subnet1-public" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet1_cidr}"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.public_subnet1_name}"
  }
}

resource "aws_subnet" "subnet2-public" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet2_cidr}"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.public_subnet2_name}"
  }
}

resource "aws_subnet" "subnet3-public" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet3_cidr}"
  availability_zone = "us-east-1c"

  tags = {
    Name = "${var.public_subnet3_name}"
  }

}


resource "aws_route_table" "terraform-public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags = {
    Name = "${var.Main_Routing_Table}"
  }
}

resource "aws_route_table_association" "terraform-public" {
  subnet_id      = "${aws_subnet.subnet1-public.id}"
  route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#data "aws_ami" "my_ami" {
#   most_recent      = true
#  owners           = ["519038273189"]
#}


resource "aws_instance" "web-1" {
  #ami = "${data.aws_ami.my_ami.id}"
  ami                         = "ami-09e67e426f25ce0d7"
  availability_zone           = "us-east-1a"
  instance_type               = "t2.medium"
  key_name                    = "keyname"
  subnet_id                   = "${aws_subnet.subnet1-public.id}"
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = true
  tags = {
    Name       = "Server-1"
    Env        = "Prod"
    Owner      = "ssvkart5"
    CostCenter = "ABCD"
  }

}
resource "null_resource" "cluster" {
  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("key.pem")}"
      host        = "${aws_instance.web-1.public_ip}"
    }

  }
  provisioner "remote-exec" { # This will execute on remote server
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo bash /tmp/script.sh",
      #"sudo apt update -y",
      #"sudo curl https://get.docker.com |bash",
      #"sudo service docker start"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("ssvkart-key.pem")}"
      host        = "${aws_instance.web-1.public_ip}"
    }
  }

  provisioner "local-exec" { # This will run in locally by collecting the details of remote server
    command = <<EOH
    echo "${aws_instance.web-1.public_ip}" >> details && echo "${aws_instance.web-1.private_ip}" >> details,
    EOH
  }
  # ...
}

resource "aws_s3_bucket" "example" { # it will create bucket and prevents if you want to destroy
  bucket = "ssvkart-bucket1"
  lifecycle {
    #prevent_destroy = true
    create_before_destroy = true
  }

}

##output "ami_id" {
#  value = "${data.aws_ami.my_ami.id}"
#}
#!/bin/bash
# echo "Listing the files in the repo."
# ls -al
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Packer Now...!!"
# packer build -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Terraform Now...!!"
# terraform init
# terraform apply --var-file terraform.tfvars -var="aws_access_key=AAAAAAAAAAAAAAAAAA" -var="aws_secret_key=BBBBBBBBBBBBB" --auto-approve