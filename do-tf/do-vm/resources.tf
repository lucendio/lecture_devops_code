resource digitalocean_tag "vm-tag" {
  name = "${ var.pid }"
}

resource digitalocean_droplet "vm" {
  name = "${ var.hostname }"

  image = "${ data.digitalocean_image.vm-image.image }"
  region = "${ var.regionId }"
  size = "${ var.size }-${ var.cpus }vcpu-${ var.memory }"
  ssh_keys = [ "${ digitalocean_ssh_key.vm-ssh-key.fingerprint }" ]

  backups = false
  monitoring = false
  private_networking = false
  ipv6 = false
  resize_disk = false

  tags = [ "${ digitalocean_tag.vm-tag.id }" ]
}

resource "digitalocean_ssh_key" "vm-ssh-key" {
  name = "${ var.pid }-ssh-key"
  public_key = "${ file( join( "", list( var.sshKeyFilePath, ".pub" ) ) ) }"
}
