variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Resource name prefix."
  type        = string
  default     = "innovatech"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 size for the k3s node. t3.medium (2 vCPU/4GB) is a good minimum."
  type        = string
  default     = "t3.medium"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form (e.g. 1.2.3.4/32) for SSH + k8s API access. Find yours at https://checkip.amazonaws.com. Leaving 0.0.0.0/0 is open to the whole internet - set your own IP for least privilege!"
  type        = string
  default     = "0.0.0.0/0"
}

# --- PostgreSQL (runs inside the cluster) ---
variable "db_name" {
  type    = string
  default = "innovatech"
}
variable "db_username" {
  type    = string
  default = "appadmin"
}
variable "db_password" {
  description = "Password for the in-cluster Postgres. Pass via tfvars or TF_VAR_db_password; never commit it."
  type        = string
  sensitive   = true
}
