Jenkins role
============


* jenkins runs in a container
* containerized process is managed by systemd
* wizard is disabled
* plugins are installed during play, ...
    a) if a `${JENKINS_HOME}/plugins` directory does not already exist
    b) depending on which `plugin_list` is referenced from `./files`
* initial credentials are set based on variables
* if `agent_secret` is set, an agent running in a container is spawned 
* agent comes with docker CLI and mounts `/var/run/docker.sock`, 
  therefore it supports building images and running container
