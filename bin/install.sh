#!/bin/sh

openstack baremetal import --json ~/instackenv.json

for i in `ironic node-list | grep ceph | awk '{print $2}'`; do ironic node-update $i add properties/capabilities='profile:ceph-storage,boot_option:local'; done 
for i in `ironic node-list | grep compute | awk '{print $2}'`; do ironic node-update $i add properties/capabilities='profile:compute,boot_option:local'; done 
for i in `ironic node-list | grep ctrl | awk '{print $2}'`; do ironic node-update $i add properties/capabilities='profile:control,boot_option:local'; done
for i in `ironic node-list | grep available | awk '{print $2}'`; do ironic node-update $i add properties/root_device='{"serial": "QM00001"}'; done
for i in `ironic node-list | grep available | awk '{print $2}'`; do ironic node-set-power-state $i off; done

sudo systemctl restart openstack-ironic-inspector
openstack baremetal configure boot
openstack baremetal introspection bulk start

openstack overcloud deploy --templates \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e /home/stack/templates/network-environment.yaml \
  -e /home/stack/templates/storage-environment.yaml \
  --control-flavor control \
  --compute-flavor compute \
  --ceph-storage-flavor ceph-storage \
  --control-scale 3 --compute-scale 2 --ceph-storage-scale 4 \
  --ntp-server pool.ntp.org \
  --neutron-network-type vxlan --neutron-tunnel-types vxlan

