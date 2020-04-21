variable "base_domain" {}

provider "digitalocean" {}

resource "digitalocean_domain" "default" {
  name = var.base_domain
}
