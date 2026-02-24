resource "oci_core_drg" "data-lake-drg" {
  compartment_id = var.compartment_ocid
  display_name   = "Data Lake DRG"
}

resource "oci_core_drg_attachment" "data-lake-drg-attachment" {
  drg_id     = oci_core_drg.data-lake-drg.id
  vcn_id     = oci_core_vcn.vcn-data-lake.id
  display_name = "Data Lake DRG Attachment"
}

resource "oci_core_cpe" "data-lake-cpe" {
  compartment_id = var.compartment_ocid
  display_name   = "Data Lake CPE"
  ip_address     = var.PublicIP_vpn
}

resource "oci_core_ipsec" "data-lake-ipsec" {
  compartment_id = var.compartment_ocid
  drg_id         = oci_core_drg.data-lake-drg.id
  cpe_id         = oci_core_cpe.data-lake-cpe.id
  cpe_local_identifier = "${var.PrivateIP}"
  display_name   = "Data Lake IPSec Connection"
  static_routes  = ["${var.StaticRoute}"] 
}

resource "oci_core_ipsec_connection_tunnel_management" "data-lake-ipsec-tunnel1" {
  tunnel_id           = data.oci_core_ipsec_connection_tunnels.tunnels.ip_sec_connection_tunnels[0].id
  ipsec_id            = oci_core_ipsec.data-lake-ipsec.id
  ike_version         = var.IKEversion
  nat_translation_enabled = "ENABLED"  
  routing             = "STATIC"
}

resource "oci_core_ipsec_connection_tunnel_management" "data-lake-ipsec-tunnel2" {
  tunnel_id           = data.oci_core_ipsec_connection_tunnels.tunnels.ip_sec_connection_tunnels[1].id
  ipsec_id            = oci_core_ipsec.data-lake-ipsec.id
  ike_version         = var.IKEversion 
  nat_translation_enabled = "ENABLED"  
  routing             = "STATIC"  
}