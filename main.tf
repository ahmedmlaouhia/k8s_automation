terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create a VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "k8s_security_group" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Allow 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # Allow SSH access from the internet
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # Allow Kubelet API access from the internet
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to custom TCP port 10256 from the internet
  ingress {
    description = "Custom TCP Port 10256"
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort services (30000-32767) from the internet
  ingress {
    description = "NodePort Services (30000-32767)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow API Server access from the internet
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow etcd access from the subnet CIDR
  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # Allow kube-scheduler access from the subnet CIDR
  ingress {
    description = "kube-scheduler"
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # Allow kube-controller-manager access from the subnet CIDR
  ingress {
    description = "kube-controller-manager"
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # Allow CoreDNS access from the subnet CIDR
  ingress {
    description = "CoreDNS"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # Allow etcd peer communication (if using etcd cluster)
  ingress {
    description = "etcd peer communication"
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.k8s_subnet.cidr_block]
  }

  # allow http traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-security-group"
  }
}

# create internet gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
}

# create route table
resource "aws_route_table" "k8s_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }
}

# associate route table with subnet
resource "aws_route_table_association" "k8s_route_table_association" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_route_table.id
}

#create key pair
resource "aws_key_pair" "k8s_key_pair" {
  key_name   = "k8s-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}


# create controle plane instances
resource "aws_instance" "k8s-Control1" {
  subnet_id              = aws_subnet.k8s_subnet.id
  instance_type          = "t2.medium"
  ami                    = "ami-0866a3c8686eaeeba"
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  key_name               = aws_key_pair.k8s_key_pair.key_name
  user_data              = <<-EOF
                            #!/bin/bash
                            hostnamectl set-hostname k8s-Control-plane-1
                            EOF
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }
  tags = {
    Name = "k8s-Control-plane-1"
  }
  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}

resource "aws_instance" "k8s-Control2" {
  subnet_id              = aws_subnet.k8s_subnet.id
  instance_type          = "t2.medium"
  ami                    = "ami-0866a3c8686eaeeba"
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  key_name               = aws_key_pair.k8s_key_pair.key_name
  user_data              = <<-EOF
                            #!/bin/bash
                            hostnamectl set-hostname k8s-Control-plane-2
                            EOF
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }

  tags = {
    Name = "k8s-Control-plane-2"
  }
  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}

# create worker nodes
resource "aws_instance" "k8s-Worker1" {
  subnet_id              = aws_subnet.k8s_subnet.id
  instance_type          = "t2.medium"
  ami                    = "ami-0866a3c8686eaeeba"
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  key_name               = aws_key_pair.k8s_key_pair.key_name
  user_data              = <<-EOF
                            #!/bin/bash
                            hostnamectl set-hostname k8s-Worker-1
                            EOF
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
  }

  tags = {
    Name = "k8s-Worker-1"
  }
  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}

resource "aws_instance" "k8s-Worker2" {
  subnet_id              = aws_subnet.k8s_subnet.id
  instance_type          = "t2.medium"
  ami                    = "ami-0866a3c8686eaeeba"
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  key_name               = aws_key_pair.k8s_key_pair.key_name
  user_data              = <<-EOF
                            #!/bin/bash
                            hostnamectl set-hostname k8s-Worker-2
                            EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
  }
  tags = {
    Name = "k8s-Worker-2"
  }
  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}

resource "aws_instance" "k8s-Worker3" {
  subnet_id              = aws_subnet.k8s_subnet.id
  instance_type          = "t2.medium"
  ami                    = "ami-0866a3c8686eaeeba"
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  key_name               = aws_key_pair.k8s_key_pair.key_name
  user_data              = <<-EOF
                            #!/bin/bash
                            hostnamectl set-hostname k8s-Worker-3
                            EOF
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
  }
  tags = {
    Name = "k8s-Worker-3"
  }
  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

}

# create elastic IPs for control plane instances
resource "aws_eip" "k8s-control1-eip" {
  domain   = "vpc"
  instance = aws_instance.k8s-Control1.id
}

resource "aws_eip" "k8s-control2-eip" {
  domain   = "vpc"
  instance = aws_instance.k8s-Control2.id
}

# create elastic IPs for worker nodes
resource "aws_eip" "k8s-worker1-eip" {
  domain   = "vpc"
  instance = aws_instance.k8s-Worker1.id
}

resource "aws_eip" "k8s-worker2-eip" {
  domain   = "vpc"
  instance = aws_instance.k8s-Worker2.id
}

resource "aws_eip" "k8s-worker3-eip" {
  domain   = "vpc"
  instance = aws_instance.k8s-Worker3.id
}

output "k8s_control1_eip" {
  value       = aws_eip.k8s-control1-eip.public_ip
  description = "Elastic IP of k8s-Control1"
}

output "k8s_control2_eip" {
  value       = aws_eip.k8s-control2-eip.public_ip
  description = "Elastic IP of k8s-Control2"
}

output "k8s_worker1_eip" {
  value       = aws_eip.k8s-worker1-eip.public_ip
  description = "Elastic IP of k8s-Worker1"
}

output "k8s_worker2_eip" {
  value       = aws_eip.k8s-worker2-eip.public_ip
  description = "Elastic IP of k8s-Worker2"
}

output "k8s_worker3_eip" {
  value       = aws_eip.k8s-worker3-eip.public_ip
  description = "Elastic IP of k8s-Worker3"
}
