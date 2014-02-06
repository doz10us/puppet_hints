#CLOUDSTACK centos

#add repo

**/etc/yum.repos.d/cloudstack.repo**
```
[cloudstack]
name=cloudstack
baseurl=http://cloudstack.apt-get.eu/rhel/4.2/
enabled=1
gpgcheck=0
```
```
yum update
```

#install and configure stuff

```
yum update 
yum install ntp 
yum install mysql-server
service ntpd start 
chkconfig ntpd on 
service mysqld start 
chkconfig mysqld on 
mysql_secure_installation
```

**/etc/my.cnf**

add following into  [mysqld] section:  

```
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
```

**disable SELinux**  

check
```
rpm -qa | grep selinux
```
disable
```
setenforce permissive
vi /etc/selinux/config
```
```
SELINUX=permissive
```
#install cloud management server
```
yum install cloudstack-management
```

**config databases**

following creates user cloud with pass \<dbpassword>, deployed by root user with pass \<password> 

```
cloudstack-setup-databases cloud:<dbpassword>@localhost \
--deploy-as=root:<password> \
-e <encryption_type> \
-m <management_server_key> \
-k <database_key> \
-i <management_server_ip>
```
example:
```
cloudstack-setup-databases cloud:gfhtsh@localhost \
--deploy-as=root:gfhtsh \
-i cloudstack.tech-corps.com
```

```
cloudstack-setup-management
```

#NFS

```
yum install nfs-utils 
mkdir -p /export/primary 
mkdir -p /export/secondary 
```
**/etc/exports **
```
/export  *(rw,async,no_root_squash,no_subtree_check) 
```
```
exportfs -a 
```
**/etc/sysconfig/nfs **
``` 
LOCKD_TCPPORT=32803 
LOCKD_UDPPORT=32769 
MOUNTD_PORT=892 
RQUOTAD_PORT=875 
STATD_PORT=662 
STATD_OUTGOING_PORT=2020 
```
```
service rpcbind start 
service nfs start 
chkconfig nfs on 
chkconfig rpcbind on 
reboot 
mkdir -p /mnt/primary 
mkdir -p /mnt/secondary 
mount -t nfs 10.50.128.1:/export/primary /mnt/primary 
mount -t nfs 10.50.128.1:/export/secondary /mnt/secondary
```

#create template
```
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://download.cloud.com/templates/4.2/systemvmtemplate-2013-06-12-master-kvm.qcow2.bz2 -h kvm -s -F
```