output "project-info" {
  value = "${ var.projectId }: ${ var.projectDescription}"
}

output "vm-info" {
  value = "${ module.vm.vm-name } via ${ module.vm.vm-ipv4 }"
}

output vm-ipv4 {
  value = "${ module.vm.vm-ipv4 }"
}
