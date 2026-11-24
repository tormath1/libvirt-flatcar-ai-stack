variable "instances" {
  type = number
}

variable "config" {
  type = string
}

variable "suffix" {
  type = string
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
