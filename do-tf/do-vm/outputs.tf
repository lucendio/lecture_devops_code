output vm-name {
  value = "${ digitalocean_droplet.vm.name }"
}

output vm-ipv4 {
  value = "${ digitalocean_droplet.vm.ipv4_address }"
}
