provider "digitalocean" {}

resource "digitalocean_ssh_key" "default" {
  name       = "default"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "digitalocean_droplet" "example" {
  image    = "debian-10-x64"
  name     = "example"
  region   = "fra1"
  size     = "s-1vcpu-1gb"
  ssh_keys = [
    digitalocean_ssh_key.default.fingerprint
  ]
}

output "ip_addr" {
  value = digitalocean_droplet.example.ipv4_address
}

output "example_price_hourly" {
  value = digitalocean_droplet.example.price_monthly
}