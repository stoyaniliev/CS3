output "k3s_public_ip" {
  description = "Public IP of the k3s node."
  value       = aws_eip.k3s.public_ip
}

output "ssh_command" {
  description = "SSH into the node."
  value       = "ssh -i k3s-key.pem ec2-user@${aws_eip.k3s.public_ip}"
}

output "get_kubeconfig" {
  description = "Fetch the kubeconfig to your laptop, then: export KUBECONFIG=$PWD/kubeconfig"
  value       = "ssh -o StrictHostKeyChecking=no -i k3s-key.pem ec2-user@${aws_eip.k3s.public_ip} \"sudo cat /etc/rancher/k3s/k3s.yaml\" | sed \"s/127.0.0.1/${aws_eip.k3s.public_ip}/\" > kubeconfig"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
