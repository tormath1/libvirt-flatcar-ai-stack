module "instance" {
  source = "../instance"

  suffix = "control-plane"
  config = templatefile("${path.module}/config.yaml.tmpl", {
    kubernetes_version       = var.kubernetes_version
    kubernetes_minor_version = join(".", [split(".", var.kubernetes_version)[0], split(".", var.kubernetes_version)[1]])
  })
  instances              = var.instances
  ssh_keys               = var.ssh_keys
  flatcar_image          = var.flatcar_image
  flatcar_instances_pool = var.flatcar_instances_pool
}
