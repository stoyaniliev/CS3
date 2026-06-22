# Ubuntu 22.04 AMI for the mesh nodes (headscale .deb + tailscale install are
# best-documented on Ubuntu). The k3s node stays on Amazon Linux, untouched.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ---------------- Headscale control plane ----------------
resource "aws_eip" "headscale" {
  domain = "vpc"
}

resource "aws_security_group" "headscale" {
  name        = "${var.project}-headscale-sg"
  description = "Headscale control plane"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "Headscale API/coordination (from you + the router)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr, "${aws_eip.router.public_ip}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "headscale" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.mesh_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.headscale.id]
  key_name                    = aws_key_pair.k3s.key_name

  user_data = templatefile("${path.module}/headscale-install.sh.tftpl", {
    headscale_version = var.headscale_version
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  tags = { Name = "${var.project}-headscale" }
}

resource "aws_eip_association" "headscale" {
  instance_id   = aws_instance.headscale.id
  allocation_id = aws_eip.headscale.id
}

# ---------------- Tailscale subnet router ----------------
resource "aws_eip" "router" {
  domain = "vpc"
}

resource "aws_security_group" "mesh_router" {
  name        = "${var.project}-router-sg"
  description = "Tailscale subnet router"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "router" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.mesh_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mesh_router.id]
  key_name                    = aws_key_pair.k3s.key_name

  # REQUIRED for a subnet router: it must be allowed to forward packets.
  source_dest_check = false

  user_data = file("${path.module}/subnet-router-install.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  tags = { Name = "${var.project}-subnet-router" }
}

resource "aws_eip_association" "router" {
  instance_id   = aws_instance.router.id
  allocation_id = aws_eip.router.id
}
