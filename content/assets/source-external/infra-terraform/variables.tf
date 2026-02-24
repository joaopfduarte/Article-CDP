variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "private_key_path" {
  default = ""
}

variable "user_ocid" {
  default = ""
}

variable "fingerprint" {
  default = ""
}

variable "public_ssh_key" {
  default = ""
}

variable "memory_in_gbs_master" {
  default = 6
}

variable "ocpus_master" {
  default = 1
}

variable "generate_public_ssh_key" {
  default = false
}

variable "instance_shape" {
  default = "VM.Standard.A1.Flex"
}

variable "image_operating_system" {
  default = "Oracle Linux"
}

variable "image_operating_system_version" {
  default = "9"
}

variable "instance_visibility_master" {
  default = "Public"
}


variable "cluster_profile" {
  description = "Profile for the cluster deployment (default, data-science, software-engineering)"
  default     = "default"
  validation {
    condition     = contains(["default", "data-science", "software-engineering"], var.cluster_profile)
    error_message = "The cluster_profile must be one of: default, data-science, software-engineering."
  }
}


# Compute Worker

variable "memory_in_gbs_worker" {
  default = 6
}

variable "ocpus_worker" {
  default = 1
}

variable "instance_visibility_worker" {
  default = "Public"
}

variable "installAmbari" {
  default = true
}

variable "PublicIP" {
  default = "10.0.0.2"
}

variable "PublicIP_vpn" {
  default = "10.0.0.2"
}

variable "StaticRoute" {
  default = "192.168.0.0/24"
}

variable "PrivateIP" {
  default = "192.168.0.3"
}

variable "IKEversion" {
  default = "V2"
}

# IP público do cliente que acessa as UIs via navegador
# IMPORTANTE: Este é o IP do SEU notebook/computador, não da máquina OCI
# Obtenha seu IP em: https://api.ipify.org ou https://whatismyip.com
variable "my_client_ip" {
  description = "Lista de IPs públicos (separados por vírgula) que acessarão as interfaces web. Ex: 203.0.113.1, 198.51.100.2"
  type        = string
  # SEM default - força usuário a fornecer o IP ao criar a Stack
}