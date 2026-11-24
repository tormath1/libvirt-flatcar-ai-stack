resource "libvirt_pool" "flatcar-images" {
  name = "flatcar-images"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/flatcar-images"
  }
}

resource "libvirt_pool" "flatcar-instances" {
  name = "flatcar-instances"
  type = "dir"
  target = {
    path = "/var/lib/libvirt/images/flatcar-instances"
  }
}

# Volume from HTTP URL upload
resource "libvirt_volume" "flatcar" {
  # TODO: Add variables here
  name = "flatcar_production_qemu_uefi_image.img"
  pool = libvirt_pool.flatcar-images.name
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      # TODO: Add variables here
      url = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_uefi_image.img"
    }
  }
}
