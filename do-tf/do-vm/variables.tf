variable pid {
  description = "uniquie project identifier"
  type        = "string"
}


variable hostname {
  description = "hostname of the virtual machine"
  type        = "string"
}

variable size {
  description = "short label (singel charecter) for the size if the virtual machine"
  type        = "string"
  default     = "s"
}

variable cpus {
  description = "number of cores"
  type        = "string"
  default     = "1"
}

variable memory {
  description = "amount of memory for the virtual machine"
  type        = "string"
  default     = "1gb"
}

variable imageId {
  description = "Name of the virtual machine's image, incl. operating system"
  type        = "string"
}

variable regionId {
  description = "DO's unique identifer for the region where the machine will reside"
  type        = "string"
}


variable sshKeyFilePath {
  description = "path to ssh key pair files (w/o file extension"
  type        = "string"
}
