data "ct_config" "flatcar" {
  count   = var.instances
  content = var.config
  strict  = true
  snippets = [
    templatefile("${path.module}/config.yaml.tmpl", {
      hostname = "${var.suffix}-${count.index}"
      ssh_keys = jsonencode(var.ssh_keys)
    }),
  ]
}

resource "libvirt_ignition" "flatcar" {
  count   = var.instances
  name    = "${var.suffix}.json"
  content = data.ct_config.flatcar[count.index].rendered
}


resource "libvirt_domain" "flatcar" {
  count       = var.instances
  name        = "${var.suffix}-${count.index}"
  memory      = 4096
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"

  running = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = "efi"
    firmware_info = {
      features = [
        { enabled = "no", name = "enrolled-keys" },
        { enabled = "no", name = "secure-boot" },
      ]
    }
  }

  features = {
    acpi = true
  }

  sys_info = [
    {
      fw_cfg = {
        entry = [
          {
            name  = "opt/org.flatcar-linux/config"
            file  = libvirt_ignition.flatcar[count.index].path
            value = ""
          }
        ]
      }
    }
  ]

  devices = {
    graphics = [
      {
        vnc = {
          auto_port = true
        }
      }
    ]
    disks = [
      {
        driver = {
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = var.flatcar_instances_pool
            volume = libvirt_volume.flatcar-disk[count.index].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        boot = {
          order = "1"
        }
      },
    ]
    interfaces = [
      {
        wait_for_ip = {
          source  = "lease"
          timeout = "300"
        }
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
  }
}

data "libvirt_domain_interface_addresses" "flatcar" {
  count  = var.instances
  domain = libvirt_domain.flatcar[count.index].name
  source = "lease"
}
