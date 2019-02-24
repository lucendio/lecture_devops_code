output "Project Info" {
  value = "${ var.projectId }: ${ var.projectDescription}"
}

output "VM Info" {
  value = "${ module.vm.vm-name } via ${ module.vm.vm-ipv4 }"
}

output vm-ipv4 {
  value = "${ module.vm.vm-ipv4 }"
}
