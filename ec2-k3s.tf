# Latest Amazon Linux 2023 AMI (uses ec2:DescribeImages, which is allowed).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Auto-generate an SSH key pair and save the private key locally as k3s-key.pem.
resource "tls_private_key" "k3s" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "k3s" {
  key_name   = "${var.project}-k3s"
  public_key = tls_private_key.k3s.public_key_openssh
}

resource "local_sensitive_file" "k3s_pem" {
  content         = tls_private_key.k3s.private_key_openssh
  filename        = "${path.module}/k3s-key.pem"
  file_permission = "0600"
}

# Stable public IP so the kubeconfig keeps working across reboots.
resource "aws_eip" "k3s" {
  domain = "vpc"
}

# Least-privilege firewall (REQ-08): SSH + k8s API limited to your IP; web open.
resource "aws_security_group" "k3s" {
  name        = "${var.project}-k3s-sg"
  description = "k3s node access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "Tailscale (WireGuard direct connections)"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k3s" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.node_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  key_name                    = aws_key_pair.k3s.key_name

  user_data = templatefile("${path.module}/k3s-install.sh.tftpl", {
    tls_san = aws_eip.k3s.public_ip
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true # encryption at rest
  }

  tags = { Name = "${var.project}-k3s" }
}

resource "aws_eip_association" "k3s" {
  instance_id   = aws_instance.k3s.id
  allocation_id = aws_eip.k3s.id
}
