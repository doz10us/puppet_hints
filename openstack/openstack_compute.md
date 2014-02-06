#install nova
```
apt-get install nova-compute-kvm python-guestfs
```

#Enable IP_Forwarding:
```
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
```
#install kvm
```
apt-get install -y kvm libvirt-bin pm-utils
```

***/etc/libvirt/qemu.conf***
```
cgroup_device_acl = [
"/dev/null", "/dev/full", "/dev/zero",
"/dev/random", "/dev/urandom",
"/dev/ptmx", "/dev/kvm", "/dev/kqemu",
"/dev/rtc", "/dev/hpet","/dev/net/tun"
]
```
***Delete default virtual bridge***
```
virsh net-destroy default
virsh net-undefine default
```
***/etc/libvirt/libvirtd.conf***

Enable live migration
```
listen_tls = 0
listen_tcp = 1
auth_tcp = "none"
```
***/etc/default/libvirt-bin.conf***
```
libvirtd_opts="-d -l"
```
***Restart the libvirt service and dbus to load the new values:***
```
service dbus restart && service libvirt-bin restart
```
#openvswitch
***Install the openVSwitch***
```
apt-get install -y openvswitch-switch openvswitch-datapath-dkms
```
***bridges***
```
#br-int will be used for VM integration
ovs-vsctl add-br br-int
```
*** /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini***
```
[ovs]
tenant_network_type = gre
tunnel_id_ranges = 1:1000
enable_tunneling = True
integration_bridge = br-int
tunnel_bridge = br-tun
local_ip = DATA_INTERFACE_IP
```

