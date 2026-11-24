resource "libvirt_volume" "flatcar-disk" {
  count = var.instances
  name  = "flatcar-${var.suffix}-${count.index}.qcow2"
  pool  = var.flatcar_instances_pool
  backing_store = {
    path = var.flatcar_image
    format = {
      type = "qcow2"
    }
  }
  target = {
    format = {
      type = "qcow2"
    }
  }

  capacity = 40737418240 # 30 GB
}
