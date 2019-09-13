#!/bin/sh

for i in master{0..2}
do 
  virt-install --name="ocp4-${i}" --vcpus=4 --ram=12288 \
  --disk path="$1"/ocp4-${i}.qcow2,bus=virtio,size=120 \
  --os-variant rhel8.0 --network network="$2",model=virtio \
  --boot menu=on --print-xml > ocp4-$i.xml
  virsh define --file ocp4-$i.xml
done

for i in worker{0..2} bootstrap
do 
  virt-install --name="ocp4-${i}" --vcpus=4 --ram=8192 \
  --disk path="$1"/ocp4-${i}.qcow2,bus=virtio,size=120 \
  --os-variant rhel8.0 --network network="$2",model=virtio \
  --boot menu=on --print-xml > ocp4-$i.xml
  virsh define --file ocp4-$i.xml
done
