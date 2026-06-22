output "headscale_public_ip" {
  description = "Headscale control-plane public IP."
  value       = aws_eip.headscale.public_ip
}
output "subnet_router_public_ip" {
  description = "Tailscale subnet router public IP."
  value       = aws_eip.router.public_ip
}
