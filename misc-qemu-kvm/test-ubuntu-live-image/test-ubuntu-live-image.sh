#!/bin/sh
wget -P /var/lib/libvirt/images/ https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso

virt-install   --name test-ubuntu-vm   --ram 2048   --vcpus 2   --disk size=20   --cdrom /var/lib/libvirt/images/ubuntu-22.04.1-live-server-amd64.iso   --os-type linux   --os-variant ubuntu22.04   --network network=default   --graphics spice
