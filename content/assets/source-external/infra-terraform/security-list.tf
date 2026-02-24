# Parse da lista de IPs (ex: "1.1.1.1, 2.2.2.2") para lista ["1.1.1.1", "2.2.2.2"]
locals {
  client_ips = split(",", replace(var.my_client_ip, " ", ""))
}

resource "oci_core_security_list" "Security-List-vcn-data-lake" {
  compartment_id = var.compartment_ocid
  display_name = "Security List for vcn-data-lake"
  vcn_id = oci_core_vcn.vcn-data-lake.id
  


  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }

  ingress_security_rules {
    source      = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "true"
    protocol  = "all"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }

# HDFS NameNode - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "50070"
        max = "50070"
      }
    }
  }

# YARN ResourceManager - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "8088"
        max = "8088"
      }
    }
  }

# MapReduce Job History - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "19888"
        max = "19888"
      }
    }
  }

# Ambari Web UI - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "8080"
        max = "8080"
      }
    }
  }

# Spark History Server - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "18082"
        max = "18082"
      }
    }
  }
 
# NiFi Web UI - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "9090"
        max = "9090"
      }
    }
  }
  
# NiFi HTTPS - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "9091"
        max = "9091"
      }
    }
  }

# Ranger Admin Web UI - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "6080"
        max = "6080"
      }
    }
  }

# HBase Master Web UI - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "16010"
        max = "16010"
      }
    }
  }

# HiveServer2 JDBC - Acesso do cliente (Multi Acesso)
  dynamic "ingress_security_rules" {
    for_each = local.client_ips
    content {
      protocol    = "6"  
      source      = "${ingress_security_rules.value}/32"
      source_type = "CIDR_BLOCK"
      stateless   = "false"
      tcp_options {
        min = "10000"
        max = "10000"
      }
    }
  }

# VPN connection (port 500, 4500 UDP)
  ingress_security_rules {
    protocol    = "17"
    source      = "${var.PublicIP_vpn}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      min = "500"
      max = "500"
    }
  }
ingress_security_rules {
    protocol    = "17"  
    source      = "${var.PublicIP_vpn}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      min = "4500"
      max = "4500"
    }
  }
}