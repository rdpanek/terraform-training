variable "base_domain" {}

provider "digitalocean" {}

variable "vm_count" {
  default = 1
}

data "digitalocean_ssh_key" "default" {
  name = "rdpanek"
}

data "digitalocean_domain" "default" {
  name = var.base_domain
}

resource "digitalocean_droplet" "example" {
  count = var.vm_count

  image    = "debian-10-x64"
  name     = "example${count.index}"
  region   = "fra1"
  size     = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.default.fingerprint
  ]

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y nginx",
    ]
  }

  provisioner "file" {
    source      = "../provisioners/index.html"
    destination = "/var/www/html/index.html"
  }

  provisioner "local-exec" {
    command = "curl ${self.ipv4_address}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "curl ${self.ipv4_address}"
  }
}

resource "digitalocean_record" "example" {
  count = var.vm_count

  domain = data.digitalocean_domain.default.name
  type   = "A"
  name   = digitalocean_droplet.example[count.index].name
  value  = digitalocean_droplet.example[count.index].ipv4_address
}

resource "digitalocean_record" "lb" {
  domain = data.digitalocean_domain.default.name
  type   = "A"
  name   = "lb"
  value  = digitalocean_loadbalancer.public.ip
}


resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = "fra1"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "tcp"
  }

  droplet_ids = [
    for inst in digitalocean_droplet.example: inst.id
  ]
}

output "vm_domains" {
  value = [
    for instance in digitalocean_record.example: instance.fqdn
  ]
}

output "lb_domains" {
  value = digitalocean_record.lb.fqdn
}