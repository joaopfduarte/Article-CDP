data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "compute_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_regions" "filtered_regions" {
  filter {
    name = "name"
    values = [var.region]
  }
}

data "oci_identity_region_subscriptions" "region" {
  tenancy_id = var.tenancy_ocid
}

data "oci_core_ipsec_connection_tunnels" "tunnels" {
  ipsec_id = oci_core_ipsec.data-lake-ipsec.id
}