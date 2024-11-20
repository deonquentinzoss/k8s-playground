terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_domain" "k8s_nodes" {
  count = 3
  name  = "k8s-node-${count.index}"
  memory = 2048
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.k8s_volume[count.index].id
  }

  network_interface {
    network_name = "default"
  }

  cloudinit = libvirt_cloudinit_disk.common.id
}

resource "libvirt_volume" "k8s_volume" {
  count  = 3
  name   = "k8s-node-${count.index}.qcow2"
  pool   = "default"
  source = "/var/lib/libvirt/images/ubuntu-20.04-minimal-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "common" {
  name      = "cloud-init.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
hostname: k8s-node
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQClaMDw02Yb+VNOgIOFrXVjDmmgTLWvFiXteHsEOg6cmwslFOM3qGlcMu+4/0ELLkaIkapfAH20efK8iIJhzL6ToeIxjBtxeA5Zxxcu45XIzGTH6R33dDVwJDxUJRj1uRTgcZthlUTqs3e/ZKbEOLjkNr0t5xGo5wiCZ5hJmydCooMU+CVAhTEw5ZVuGjJUwqrBR/qLpji0FZzwMi9+sGkxz7MTBwTVDUvrPbFN8gy0rFghdND4TvU6Ejej3sReBI7NXJHuGQsyWcG9Qqlg5lSVbOZph7tS9RDj8UeRlQf6hWDXAEqkiKdQ1gFbg8WmlRxYycVQLSjBUivaLGUS3SVht4EWfNzgvxQ9bD1AG+U0fBYanO/0fNYDaQ346Q0Z+qAso+5+Uds/HInGM3i45WZ7uXRk6CM1xynQrYNU0dBCKrrVVzXFNqGfKjk+yAl9QiJ/RpSPUPuRljLzXe/jFwE+5m370TJvWxkHkOJyYHcWulL1WllZ2zle+nqhHNoCpMsMAFeb9+LArjSAlPFtB2XX0/5KiVNIJ71EsdKSosgPkrwpQ/CiyOKNE6sqYmOUdBLdJmjHEmv+qRjQn+/j/OGlxzPoFfD9G1NxuVNoQNHA79LUDph5oEYvHpl2qKIqAvgh/lt9eM2wPSJ5YDbidxKiUN9PqRq93yDQOE5qvUi1CQ==
runcmd:
  - swapoff -a
  - sed -i '/ swap / s/^/#/' /etc/fstab
packages:
  - curl
  - apt-transport-https
  - software-properties-common
users:
  - name: ansible
    ssh_authorized_keys:
      - ssh-rsa AAAAB3Nza...your-public-key...
    sudo: ALL=(ALL) NOPASSWD:ALL
EOF
}


