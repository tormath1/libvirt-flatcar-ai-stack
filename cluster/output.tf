output "control_plane_endpoint" {
  value = module.control-plane.endpoint[0]
}

output "kubeconfig" {
  depends_on = [
    terraform_data.kubeconfig
  ]

  sensitive = true
  value     = "${path.module}/admin.conf"
}
