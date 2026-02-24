locals {
  blueprint_source = var.cluster_profile == "default" ? "assets/blueprint.json" : "assets/blueprint-${var.cluster_profile}/blueprint.json"
  cluster_template_source = var.cluster_profile == "default" ? "assets/cluster-template.json" : "assets/blueprint-${var.cluster_profile}/cluster-template.json"
}

# Master
resource "oci_core_instance" "Master" {
  
  display_name = "master.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.2"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/master.yaml",  {
      private_key_pem_b64 = base64encode(tls_private_key.compute_ssh_key.private_key_pem),
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }

  shape_config {
    memory_in_gbs             = var.memory_in_gbs_master
    ocpus                     = var.ocpus_master
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Worker 1
resource "oci_core_instance" "Node1" {
  
  display_name = "node1.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.3"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/worker.yaml",  {
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_worker
    ocpus                     = var.ocpus_worker
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Worker 2
resource "oci_core_instance" "Node2" {
  
  display_name = "node2.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.4"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/worker.yaml",  {
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_worker
    ocpus                     = var.ocpus_worker
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Worker 3
resource "oci_core_instance" "Node3" {
  
  display_name = "node3.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.5"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/worker.yaml",  {
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_worker
    ocpus                     = var.ocpus_worker
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Generate ssh keys in Worker to Master have access to Worker Workers
resource "tls_private_key" "compute_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}



resource "null_resource" "upload_assets" {
  depends_on = [oci_core_instance.Master]

  triggers = {
    master_ip = oci_core_instance.Master.public_ip
  }

  connection {
    type        = "ssh"
    user        = "opc"
    private_key = tls_private_key.compute_ssh_key.private_key_pem
    host        = oci_core_instance.Master.public_ip
    timeout     = "10m"
  }

  provisioner "file" {
    source      = local.blueprint_source
    destination = "/tmp/blueprint.json"
  }

  provisioner "file" {
    source      = "assets/ODP-VDF.xml"
    destination = "/tmp/ODP-VDF.xml"
  }

  provisioner "file" {
    source      = local.cluster_template_source
    destination = "/tmp/cluster-template.json"
  }

  provisioner "file" {
    source      = "assets/cluster_deploy.yml"
    destination = "/tmp/cluster_deploy.yml"
  }

  provisioner "file" {
    source      = "assets/site.yml"
    destination = "/tmp/site.yml"
  }

  provisioner "file" {
    source      = "assets/deploy_tasks.yml"
    destination = "/tmp/deploy_tasks.yml"
  }

  provisioner "file" {
    source      = "assets/manual_service_init.sh"
    destination = "/tmp/manual_service_init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/blueprint.json /root/blueprint.json",
      "sudo mv /tmp/ODP-VDF.xml /root/ODP-VDF.xml",
      "sudo mv /tmp/cluster-template.json /root/cluster-template.json",
      "sudo mv /tmp/cluster_deploy.yml /root/cluster_deploy.yml",
      "sudo mv /tmp/site.yml /root/site.yml",
      "sudo mv /tmp/deploy_tasks.yml /root/deploy_tasks.yml",
      "sudo mv /tmp/manual_service_init.sh /root/manual_service_init.sh",
      "sudo chmod +x /root/manual_service_init.sh",
      "sudo chown root:root /root/blueprint.json /root/ODP-VDF.xml /root/cluster-template.json /root/cluster_deploy.yml /root/site.yml /root/deploy_tasks.yml /root/manual_service_init.sh"
    ]
  }
}
