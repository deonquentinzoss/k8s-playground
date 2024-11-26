#wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

#destroy vm
virsh shutdown ubuntu-cloud-test && virsh destroy ubuntu-cloud-test

#check which disks are being used
virsh domblklist ubuntu-cloud-test

#undefine to detach disk from VM
virsh undefine ubuntu-cloud-test

cloud-localds cloud-init.iso user-data meta-data

virt-install \
  --name ubuntu-cloud-test \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/focal-server-cloudimg-amd64.img \
  --disk path=cloud-init.iso,device=cdrom \
  --os-variant ubuntu20.04 \
  --import \
  --graphics none
  

#To see IP address
#virsh domifaddr ubuntu-cloud-test

