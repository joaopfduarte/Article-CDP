terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 3.27.0"
    }
  }
  required_version = ">= 0.13"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region

  #config_file_profile = "DEFAULT"
  #ocid1.tenancy.oc1..aaaaaaaabgtanzwk3zzo4okqqxjezyzbadiuxvytlry3266ydglhpogeunwa
  #sa-saopaulo-1
  #ocid1.compartment.oc1..aaaaaaaargckss2cr5wf5a2pmxjt6deseafw2aujngch4hoynha54tvgykyq
}