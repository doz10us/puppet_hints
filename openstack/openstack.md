ПОЕХАЛИ


##ntp, mysql, rabbitmq
apt-get install ntp mysql-server(mysql pass) 
check bind-address in /etc/mysql/my.cfg
apt-get install python-argparse
apt-get install rabbitmq-server
rabbitmqctl change_password guest RABBIT_PASS

###sources
echo "deb http://archive.gplhost.com/debian havana-backports main" >>/etc/apt/sources.list
echo "deb http://archive.gplhost.com/debian havana main" >>/etc/apt/sources.list
apt-get update && apt-get install gplhost-archive-keyring
apt-get update && apt-get dist-upgrade

apt-get install keystone
>>don't set up db
>>enter token
>>don't create tenant
>>don't create endpoint

mysql -u root -p

#Keystone
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';

#Glance
CREATE DATABASE glance;
GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';

#Quantum
CREATE DATABASE quantum;
GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass';

#Nova
CREATE DATABASE nova;
GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';

#Cinder
CREATE DATABASE cinder;
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';

quit;