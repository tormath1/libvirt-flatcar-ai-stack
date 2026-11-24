module "cluster" {
  source = "./cluster"

  control_plane_instances = 1
  worker_instances        = 2
  ssh_keys                = var.ssh_keys
}
