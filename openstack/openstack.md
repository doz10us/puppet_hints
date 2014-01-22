###ПОЕХАЛИ


**ntp, mysql, rabbitmq**
```
apt-get install ntp mysql-server  (mysql pass) 
check bind-address in /etc/mysql/my.cfg
service mysql restart
apt-get install python-argparse
apt-get install rabbitmq-server
rabbitmqctl change_password guest RABBIT_PASS
```
**sources**
```
echo "deb http://archive.gplhost.com/debian havana-backports main" >>/etc/apt/sources.list
echo "deb http://archive.gplhost.com/debian havana main" >>/etc/apt/sources.list
apt-get update && apt-get install gplhost-archive-keyring
apt-get update && apt-get dist-upgrade
```
**databases**
```
mysql -u root -p

#Keystone
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';

#Glance
CREATE DATABASE glance;
GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';

#Neutron
CREATE DATABASE neutron;
GRANT ALL ON quantum.* TO 'neutronUser'@'%' IDENTIFIED BY 'neutronPass';

#Nova
CREATE DATABASE nova;
GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';

#Cinder
CREATE DATABASE cinder;
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';

quit;
```
#Keystone
**install keystone**
```
apt-get install keystone

```
don't set up db  
enter token  
don't create tenant  
don't create endpoint

**/etc/keystone/keystone.conf**
```
connection = mysql://keystoneUser:keystonePass@[mysql_host]/keystone

#if wanna more log info uncomment:
debug = False
verbose = False
```
**restart and sync with db:**
```
service keystone restart
keystone-manage db_sync
```


**create tenants, users and endpoints**
we can do it manually, or use scripts:
wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/OVS_MultiNode/KeystoneScripts/keystone_basic.sh
wget https://raw.github.com/mseknibilel/OpenStack-Grizzly-Install-Guide/OVS_MultiNode/KeystoneScripts/keystone_endpoints_basic.sh

just change admin token, IP's, names and passes there and it's ok
don't forget to change quantum to neutron
or just do the same commands manually


**create simple auth file(!!!FOR DEPLOYMENT ONLY. INSECURE. DELETE AFTER INSTALLATION COMPLETE!!!)**
```
nano creds
```
Paste the following:
```
export OS_TENANT_NAME=[admin_tenant_name]
export OS_USERNAME=[admin_username]
export OS_PASSWORD=[admin_pass]
export OS_AUTH_URL="http://[my_external_ip]:5000/v2.0/"
```
Load it:
```
source creds
```
unset token to auth by login\pass
```
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
```
**check if keystone is ok**
```
keystone user-list
```
#Glance
**install glance**
```
apt-get install -y glance python-glanceclient
```
don't set up db  
enter rabbitmq host,user,pass
enter flavor - keystone
enter keystone server ip

**/etc/glance/glance-api-paste.ini**
```
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
delay_auth_decision = true
auth_host = [internal_keystone_host]
auth_port = 35357
auth_protocol = http
admin_tenant_name = [service_tenant_name]
admin_user = [glance_user_name]
admin_password = [service_pass]
```
**/etc/glance/glance-registry-paste.ini**
```
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_host = [internal_keystone_host]
auth_port = 35357
auth_protocol = http
admin_tenant_name = [service_tenant_name]
admin_user = [glance_user_name]
admin_password = [service_pass]
```
**/etc/glance/glance-registry.conf**
```
sql_connection = mysql://glanceUser:glancePass@[mysql_host]/glance

[keystone_authtoken]
auth_host = [internal_keystone_host]
auth_port = 35357
auth_protocol = http
admin_tenant_name = [service_tenant_name]
admin_user = [glance_user_name]
admin_password = [service_pass]

[paste_deploy]
config_file = /etc/glance/glance-registry-paste.ini ???????????????????? look at docs

flavor = keystone
```
**/etc/glance/glance-api.conf**
```

sql_connection = mysql://glanceUser:glancePass@[mysql_host]/glance
[keystone_authtoken]
auth_host = [internal_keystone_host]
auth_port = 35357
auth_protocol = http
admin_tenant_name = [service_tenant_name]
admin_user = [glance_user_name]
admin_password = [service_pass]

[paste_deploy]
config_file = /etc/glance/glance-api-paste.ini ???????????????????? look at docs

flavor = keystone
```
**restart&register db**
```
service glance-api restart; service glance-registry restart
glance-manage db_sync
```
**check glance**
download image
```
mkdir images
cd images/
wget http://cdn.download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img
```
Upload the image to the Image Service
```
glance image-create --name="CirrOS 0.3.1" --disk-format=qcow2 \
  --container-format=bare --is-public=true < cirros-0.3.1-x86_64-disk.img
```
check
```
glance image-list
```

#Nova
**install nova server**
```
apt-get install nova-consoleproxy nova-api \
  nova-cert nova-conductor nova-consoleauth \
  nova-scheduler python-novaclient
```
don't set up db  
enter rabbitmq host,user,pass  
enter flavor - keystone  
enter keystone server ip   
enter preferred APIs  

**/etc/nova/api-paste.ini**
```
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_host = [internal_keystone_host]
auth_port = 35357
auth_protocol = http
admin_tenant_name = [service_tenant_name]
admin_user = [nova_user_name]
admin_password = [service_pass]
signing_dirname = /tmp/keystone-signing-nova
# Workaround for https://bugs.launchpad.net/nova/+bug/1154809
auth_version = v2.0
```

**/etc/nova/nova.conf**
```
sql_connection=mysql://novaUser:novaPass@[mysql_host]/nova

neutron_url=http://[internal_keystone_host]:9696
neutron_auth_strategy=keystone
admin_tenant_name = [service_tenant_name]
admin_user = [neutron_user_name]
admin_password = [service_pass]
# This is the URL of your Keystone server
neutron_admin_auth_url=http://[mysql_host]:35357/v2.0

vnc_enabled=true
novncproxy_base_url=http://[external_ip]:6080/vnc_auto.html
# Change vncserver_proxyclient_address and vncserver_listen to match each compute host
vncserver_proxyclient_address=openstack02
vncserver_listen=0.0.0.0
vnc_keymap="en-us"


[spice]
# location of spice html5 console proxy, in the form
# "http://www.example.com:6082/spice_auto.html" (string value)
#html5proxy_base_url=http://127.0.0.1:6082/spice_auto.html

# IP address on which instance spice server should listen (string value)
#server_listen=0.0.0.0

# the address to which proxy clients (like nova-spicehtml5proxy) should connect (string value)
#server_proxyclient_address=$my_ip

# enable spice related features (boolean value)
enabled=false

# enable spice guest agent support (boolean value)
agent_enabled=false

# keymap for spice (string value)
#keymap=en-us
```

```
nova-manage db sync
cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done
```

#Cinder
**install controller+node**
```
apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms
sed -i 's/false/true/g' /etc/default/iscsitarget

service iscsitarget start
service open-iscsi start
```

**/etc/cinder/api-paste.ini **
```
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_host = [internal_keystone_host]
auth_port = 35357
auth_protocol = http
admin_tenant_name = [service_tenant_name]
admin_user = [cinder_user_name]
admin_password = [service_pass]
```

**/etc/cinder/cinder.conf**
```
[DEFAULT]
rootwrap_config=/etc/cinder/rootwrap.conf
sql_connection = mysql://cinderUser:cinderPass@[mysql_host]/cinder
api_paste_config = /etc/cinder/api-paste.ini
iscsi_helper=ietadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
iscsi_ip_address=[internal_cinder_host]
```
**Create a 1 GB test volume.**
```
cinder create --display_name test 1
cinder list
```
#Neutron

**install**
```
apt-get install neutron-server neutron-dhcp-agent neutron-plugin-openvswitch-agent neutron-l3-agent
```
**/etc/neutron/neutron.conf**
```
auth_host = [internal_keystone_host]
admin_tenant_name = [service_tenant_name]
admin_user = [neutron_user_name]
admin_password = [service_pass]
auth_url = http://[internal_keystone_host]:35357/v2.0
auth_strategy = keystone

[database]
connection = mysql://neutronUser:neutronPass@[mysql_host]/neutron
```
** /etc/neutron/api-paste.ini**
```
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_tenant_name = [service_tenant_name]
admin_user = [neutron_user_name]
admin_password = [service_pass]
```
**/etc/nova/nova.conf**
yeah, nova
```
network_api_class=nova.network.neutronv2.api.API
neutron_url=http://[internal_keystone_host]:9696
neutron_auth_strategy=keystone
neutron_admin_tenant_name=[service_tenant_name]
neutron_admin_username=[neutron_user_name]
neutron_admin_password=[service_pass]
neutron_admin_auth_url=http://[internal_keystone_host]:35357/v2.0
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.firewall.NoopFirewallDriver
security_group_api=neutron
```
**/etc/sysctl.conf**  
Enable packet forwarding and disable packet destination filtering so that the network node can coordinate traffic for the VMs.
```
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
```
```sysctl -p```


**openvswitch**

```
service openvswitch-switch restart
```
add bridges
```
ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
```
Add a port (connection) from the EXTERNAL_INTERFACE interface to br-ex interface:
```
ovs-vsctl add-port br-ex EXTERNAL_INTERFACE
```
#####Configure the EXTERNAL_INTERFACE without an IP address and in promiscuous mode. 
Additionally, you must set the newly created br-ex interface to have the IP address that formerly belonged to EXTERNAL_INTERFACE.

```
allow-hotplug eth0
iface eth0 inet manual
        ip ifconfig $IFACE 0.0.0.0
        up ip link set $IFACE promisc on
        down ip link set $IFACE promisc off
        down ifconfig $IFACE down

auto br-ex
iface br-ex inet dhcp
```
**/etc/neutron/l3_agent.ini and /etc/neutron/dhcp_agent.ini**  
Configure the L3 and DHCP agents to use OVS and namespaces  
```
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
```
**/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini**  
Configure the OVS plug-in to use GRE tunneling, the br-int integration bridge, the br-tun tunneling bridge, and a local IP for the DATA_INTERFACE tunnel IP.

```
[ovs]
tenant_network_type = gre
tunnel_id_ranges = 1:1000
enable_tunneling = True
integration_bridge = br-int
tunnel_bridge = br-tun
local_ip = [internal_network_host]
```

**/etc/neutron/dhcp_agent.ini**

To perform DHCP on the software-defined networks, Networking supports several different plug-ins. However, in general, you use the Dnsmasq plug-in.
```
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
```

restart
```
for i in $(ls /etc/init.d/neutron*); do $i restart; done;
```
#Horizon

**install**
```
apt-get install memcached libapache2-mod-wsgi openstack-dashboard
```