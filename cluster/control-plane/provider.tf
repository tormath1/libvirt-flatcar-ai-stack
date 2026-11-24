terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    ct = {
      source = "poseidon/ct"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

