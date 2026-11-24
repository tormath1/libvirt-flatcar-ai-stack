module "control-plane" {
  source                 = "./control-plane"
  instances              = var.control_plane_instances
  flatcar_image          = libvirt_volume.flatcar.id
  flatcar_instances_pool = libvirt_pool.flatcar-instances.name
  ssh_keys               = var.ssh_keys
}

module "worker" {
  source                 = "./worker"
  instances              = var.worker_instances
  control_plane_endpoint = module.control-plane.endpoint[0]
  flatcar_image          = libvirt_volume.flatcar.id
  flatcar_instances_pool = libvirt_pool.flatcar-instances.name
  ssh_keys               = var.ssh_keys
}

resource "terraform_data" "kubeconfig" {
  provisioner "local-exec" {
    command = "curl --retry 12 --retry-all-errors -fsSL --remote-name http://${module.control-plane.endpoint[0]}:8080/admin.conf"
    quiet   = true
  }
}
