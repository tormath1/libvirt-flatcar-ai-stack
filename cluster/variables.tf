variable "control_plane_instances" {
  type = number
}

variable "worker_instances" {
  type = number
}

variable "ssh_keys" {
  type = list(string)
}
