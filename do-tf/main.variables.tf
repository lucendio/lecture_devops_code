variable projectId {
  description = "unque identifier of the project"
  type        = "string"
}

variable projectDescription {
  description = "description of the project"
  type        = "string"
}


variable sshKeyPairPath {
  description = "SSH key pair path"
  type        = "string"
  default     = "./.credentials/ssh-key"
}
