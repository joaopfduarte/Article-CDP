# Network configuration

resource "oci_core_vcn" "vcn-data-lake" {
  cidr_blocks = [
    "10.0.0.0/24",
  ]
  compartment_id = var.compartment_ocid
  display_name = "vcn-data-lake"
}

resource "oci_core_route_table" "Route-Table-vcn-data-lake" {
  compartment_id = var.compartment_ocid
  display_name = "Route Table for vcn-data-lake"
  vcn_id = oci_core_vcn.vcn-data-lake.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.Internet-Gateway-vcn-data-lake.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
  route_rules {
    network_entity_id = oci_core_drg.data-lake-drg.id  
    destination       = var.StaticRoute               
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_internet_gateway" "Internet-Gateway-vcn-data-lake" {
  compartment_id = var.compartment_ocid
  display_name = "Internet Gateway vcn data-lake"
  enabled      = "true"
  vcn_id = oci_core_vcn.vcn-data-lake.id
}

resource "oci_core_subnet" "data-lake-subnet" {
  cidr_block      = "10.0.0.0/24"
  compartment_id  = var.compartment_ocid
  dhcp_options_id = oci_core_vcn.vcn-data-lake.default_dhcp_options_id
  display_name    = "data-lake-subnet"
  route_table_id  = oci_core_route_table.Route-Table-vcn-data-lake.id
  security_list_ids = [oci_core_security_list.Security-List-vcn-data-lake.id]
  vcn_id = oci_core_vcn.vcn-data-lake.id
}