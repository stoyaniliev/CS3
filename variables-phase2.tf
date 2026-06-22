# --- RDS ---
variable "db_instance_class" {
  description = "RDS instance size (keep small for cost)."
  type        = string
  default     = "db.t3.micro"
}
variable "postgres_version" {
  description = "RDS PostgreSQL engine major version."
  type        = string
  default     = "16"
}

# --- Mesh (Headscale + subnet router) ---
variable "mesh_instance_type" {
  description = "EC2 size for the Headscale control plane and the subnet router."
  type        = string
  default     = "t3.small"
}
variable "headscale_version" {
  description = "Headscale release to install (no leading v)."
  type        = string
  default     = "0.23.0"
}
