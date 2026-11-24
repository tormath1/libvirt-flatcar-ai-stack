variable "control_plane_endpoint" {
  type = string
}

variable "instances" {
  type    = number
  default = 1
}

variable "kubernetes_version" {
  type    = string
  default = "v1.37.0"
}

variable "ssh_keys" {
  type = list(string)
}

variable "flatcar_image" {
  type = string
}

variable "flatcar_instances_pool" {
  type = string
}
