output "generated_private_key_pem" {
  sensitive = true
  value = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.private_key_pem : "No Keys Auto Generated"
}

output "comments" {
  value = "A instalação final do cluster levará cerca de 03 horas e a interface do ambari ficará disponível em ${oci_core_instance.Master.public_ip}:8080."
}
