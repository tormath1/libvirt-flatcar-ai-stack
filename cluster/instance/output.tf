output "ip" {
  value = {
    for name, data_source in data.libvirt_domain_interface_addresses.flatcar :
    name => data_source.interfaces[0].addrs[0].addr
  }
}
