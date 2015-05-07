#!/bin/sh
hostname nagios.nagios

# change host name
DIR_PATH=/etc/sysconfig/
OBJ_FILE=network

echo "the original content:"
echo ""

sed -n -e "1p" $DIR_PATH/$OBJ_FILE
sed -n -e "2p" $DIR_PATH/$OBJ_FILE

sed -i "1cNETWORKING=yes" $DIR_PATH/$OBJ_FILE
sed -i "2cHOSTNAME=nagios.nagios" $DIR_PATH/$OBJ_FILE

echo "Now, the content"
sed -n -e "1p" $DIR_PATH/$OBJ_FILE
sed -n -e "2p" $DIR_PATH/$OBJ_FILE
echo ""

# selinux change
PATH_SELINUX=/etc/selinux/
SELINUX_CONFIG=config

echo "the original content:"
echo ""
sed -n -e "7p" $PATH_SELINUX/$SELINUX_CONFIG

sed -i "7cSELINUX=disabled" $PATH_SELINUX/$SELINUX_CONFIG
echo "Now, the content"
sed -n -e "7p" $PATH_SELINUX/$SELINUX_CONFIG
echo ""

setenforce 0

sed -i "1c0 * * * * /usr/sbin/ntpdate 65.55.56.206" /var/spool/cron/root

service crond restart
ntpdate_path="/usr/sbin/ntpdate"
if [ ! -f "$ntpdate_path" ];then
echo "no ntpdate"
yum -y install ntpdate
else
echo "ntpdate done"
fi
ntpdate 65.55.56.206

vsftpd_path="/usr/sbin/vsftpd"
if [ ! -f "$vsftpd_path" ];then
echo "no vsftpd"
yum -y install vsftpd
else
echo "vsftpd done"
fi

# vsftpd change
path_vsftpd_conf=/etc/vsftpd/vsftpd.conf
echo "the original content:"
echo ""
sed -n -e "12p" $path_vsftpd_conf
sed -n -e "120p" $path_vsftpd_conf
sed -i "12canonymous_enable=NO"  $path_vsftpd_conf
#add useerlist_deny
if [ ! -f /home/vsftptab ];then
sed -i "119auserlist_deny=NO"  $path_vsftpd_conf
echo > /home/vsftptab
fi
#sed -i "120cuserlist_deny=NO"  $path_vsftpd_conf
echo "Now, the content"
sed -n -e "12p" $path_vsftpd_conf
sed -n -e "120p" $path_vsftpd_conf
echo ""

ftpuser=ftpuser
egrep "^$ftpuser" /etc/passwd >$ /dev/null
if [ $? -ne 0 ]
then
echo "no ftpuser"
useradd ftpuser
echo ftpuser:123456 |chpasswd
else
echo "ftpuser exist"
fi

path_vsftpd_userlist=/etc/vsftpd/user_list
echo "the original conctent:"
echo ""
sed -n -e "21p" $path_vsftpd_userlist

#add ftpuser
if [ ! -f /home/ftptab ];then
sed -i "20aftpuser" $path_vsftpd_userlist
echo > /home/ftptab
fi
#sed -i "21cftpuser" $path_vsftpd_userlist
echo "Now, the content"
sed -n -e "21p" $path_vsftpd_userlist
echo ""

/etc/init.d/vsftpd start
chkconfig vsftpd on

/sbin/service iptables status 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
 echo "iptables running"
service iptables stop
chkconfig iptables off
else
echo "iptables stopped"
fi

# Apache 
httpd_path="/usr/sbin/httpd"
if [ ! -f "$httpd_path" ];then
echo "no httpd"
yum -y install httpd
else
echo "httpd done"
fi

path_httpd_conf=/etc/httpd/conf/httpd.conf
echo "original conctent:"
echo ""
sed -n -e "402p" $path_httpd_conf
sed -n -e "403p" $path_httpd_conf
sed -n -e "781p" $path_httpd_conf
sed -n -e "782p" $path_httpd_conf
sed -n -e "277p" $path_httpd_conf

sed -i "402c# DirectoryIndex index.html index.html.var" $path_httpd_conf
sed -i "403cDirectoryIndex index.html index.php" $path_httpd_conf
sed -i "781cAddType application/x-httpd-php .php" $path_httpd_conf
sed -i "782cAddType applicaiton/x-httpd-php-source .phps" $path_httpd_conf
sed -i "277cServerName nagios.nagios" $path_httpd_conf
echo "Now conctent:"
echo ""
sed -n -e "402p" $path_httpd_conf
sed -n -e "403p" $path_httpd_conf
sed -n -e "781p" $path_httpd_conf
sed -n -e "782p" $path_httpd_conf
sed -n -e "277p" $path_httpd_conf

/sbin/service httpd status 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
echo "httpd stop"
service httpd start
chkconfig httpd on
else
echo "httpd running"
fi

# php
path_php=/usr/bin/php
if [ ! -f "$path_php" ];then
echo "no php"
yum -y install php php-devel php-snmp php-gd php-mysql
else
echo "php exist"
fi

if [ ! -f "/var/www/html/index.php" ];then
echo "no index.php"
echo > /var/www/html/index.php
sed -i "1c<?php phpinfo();?>" /var/www/html/index.php
else
echo "index.php exist"
fi

service httpd restart

# mysql
path_mysql=/usr/bin/mysql
if [ ! -f "$path_mysql" ];then
echo "no mysql"
yum -y install mysql mysql-server mysql-devel
 # start mysql and add root user 
    /sbin/service mysqld status 1>/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "mysql stop"
        service mysqld start
        chkconfig mysqld on
        else
        echo "httpd running"
     fi
      mysqladmin -u root password '123456'
  #end start mysql
else
echo "mysql exist"
fi

path_gcc=/usr/bin/gcc
if [ ! -f "$path_gcc" ];then
echo "no gcc"
yum -y install gcc
echo "gcc is OK"
yum -y install glibc glibc-common
echo "glibc is OK"
yum -y install gd gd-devel
echo "gd is OK"
yum -y install libtool libpcap libpcap-devel gdbm gdbm-devel zlib zlib-devel
echo "pcap is OK"
else
echo "gcc, glibc, gd, pcap is OK"
fi

# install Cacti

# create database cactidb

path_cactitab=/home/cactitab
if [ ! -f "$path_cactitab" ];then
echo "creat cactidb"
mysql -uroot -p123456 -e "
create database cactidb;
GRANT ALL ON cactidb.* TO cactier@localhost IDENTIFIED BY '123456';
flush privileges;
quit;"
echo "create database cactidb";
echo > /home/cactitab
else
echo "cactidb exits"
fi

# install rrdtool
path_rrdtool=/usr/bin/rrdtool
if [ ! -f "$path_rrdtool" ];then
echo "add rrdtool"
yum -y install rrdtool rrdtool-devel rrdtool-php
else
echo "rrdtool exist"
fi

path_snmptab=/home/snmptab
if [ ! -f "$path_snmptab" ];then
echo "add net-snmp"
yum -y install -y net-snmp net-snmp-utils net-snmp-libs
service snmpd restart
chkconfig snmpd on
echo > /home/snmptab
else
echo "snmp exist"
fi

path_nagios=/home/nagios
if [ ! -d "$path_nagios" ];then
echo "add nagios file"
mkdir /home/nagios
else
echo "/home/nagios file exist"
fi
cd /home/nagios
path_cacti=/var/www/html/cacti
if [ ! -d "$path_cacti" ];then
echo "install cacti"
yum -y install wget
wget 'http://www.cacti.net/downloads/cacti-0.8.8b.tar.gz'
tar xzf 'cacti-0.8.8b.tar.gz'
mv 'cacti-0.8.8b' /var/www/html/cacti
cd /var/www/html/cacti
mysql -uroot -p123456 cactidb < cacti.sql
else
echo "cacti exist"
fi

path_cacti_config=/var/www/html/cacti/include/config.php
echo "original conctent:"
echo ""
sed -n -e "26p" $path_cacti_config
sed -n -e "27p" $path_cacti_config
sed -n -e "28p" $path_cacti_config
sed -n -e "29p" $path_cacti_config
sed -n -e "30p" $path_cacti_config
sed -n -e "31p" $path_cacti_config
sed -n -e "39p" $path_cacti_config

sed -i '26c$database_type = "mysql";' $path_cacti_config
sed -i '27c$database_default = "cactidb";' $path_cacti_config
sed -i '28c$database_hostname = "localhost";' $path_cacti_config
sed -i '29c$database_username = "cactier";' $path_cacti_config
sed -i '30c$database_password = "123456";' $path_cacti_config
sed -i '31c$database_port = "3306";' $path_cacti_config
sed -i '39c$url_path = "/cacti/";' $path_cacti_config

echo "Now conctent:"
echo ""
sed -n -e "26p" $path_cacti_config
sed -n -e "27p" $path_cacti_config
sed -n -e "28p" $path_cacti_config
sed -n -e "29p" $path_cacti_config
sed -n -e "30p" $path_cacti_config
sed -n -e "31p" $path_cacti_config
sed -n -e "39p" $path_cacti_config

cactiuser=cactier
egrep "^$cactiuser" /etc/passwd >$ /dev/null
if [ $? -ne 0 ]
then
echo "no cactier"
useradd cactier
echo cactier:123456 |chpasswd
usermod -G cactier apache
cd /var/www/html/cacti
chown -R root:root /var/www/html/cacti/
chown -R cactier:cactier rra/ log/
else
echo "cactier exist"
fi
path_httpd_conf=/etc/httpd/conf/httpd.conf
path_httpd_conftab=/home/httpdconftab
if [ ! -f $path_httpd_conftab ];then
echo "original conctent:"
echo ""
sed -n -e "1010p" $path_httpd_conf
sed -n -e "1011p" $path_httpd_conf
sed -n -e "1012p" $path_httpd_conf
sed -n -e "1013p" $path_httpd_conf
sed -n -e "1014p" $path_httpd_conf
sed -n -e "1015p" $path_httpd_conf

sed -i '1009a<Directory "/var/www/html/cacti">' $path_httpd_conf
sed -i '1010aOptions FollowSymLinks MultiViews' $path_httpd_conf
sed -i "1011aAllowOverride None" $path_httpd_conf
sed -i "1012aOrder allow,deny" $path_httpd_conf
sed -i "1013aAllow from all" $path_httpd_conf
sed -i "1014a</Directory>" $path_httpd_conf

echo "Now conctent:"
echo ""
sed -n -e "1010p" $path_httpd_conf
sed -n -e "1011p" $path_httpd_conf
sed -n -e "1012p" $path_httpd_conf
sed -n -e "1013p" $path_httpd_conf
sed -n -e "1014p" $path_httpd_conf
sed -n -e "1015p" $path_httpd_conf
echo > /home/httpdconftab
else
echo "httpd_conf changed"
fi

path_php_ini=/etc/php.ini
echo "original conctent:"
echo ""
sed -n -e "947p" $path_php_ini

sed -i "947cdate.timezone=Asia/Shanghai" $path_php_ini

echo "Now conctent:"
sed -n -e "947p" $path_php_ini

service httpd restart
path_crontab=/home/crontabtable
if [ ! -f $path_crontab ];then
echo "original:"
sed -n -e "2p" /var/spool/cron/root
sed -i "1a*/5 * * * * php /var/www/html/cacti/poller.php &> /dev/null" /var/spool/cron/root
echo "Now:"
sed -n -e "2p" /var/spool/cron/root
echo > /home/crontabtable
else
echo "crontab changed"
fi

# install nagios
group=nagcmd
egrep "^$group" /etc/group >& /dev/null  
if [ $? -ne 0 ]  
then
echo "nagcmd no exist"  
    groupadd $group
    useradd -G nagcmd nagios
    usermod -a -G nagcmd apache
else  
echo "nagcmd exist"
fi

path_nagiostar=/home/nagios/nagios-3.5.1.tar.gz
if [ ! -f $path_nagiostar ];then
cd /home/nagios
wget http://jaist.dl.sourceforge.net/project/nagios/nagios-3.x/nagios-3.5.1/nagios-3.5.1.tar.gz
tar xzvf nagios-3.5.1.tar.gz
cd nagios
cmd1="./configure --with-command-group=nagcmd --enable-event-broker"
$cmd1
make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin 
service httpd restart
else
echo "nagios installded"
fi 

# install nagios-plugins
path_nagios_plugins=/home/nagios/nagios-plugins-2.0.2.tar.gz
if [ ! -f $path_nagios_plugins ];then
cd /home/nagios
wget http://nagios-plugins.org/download/nagios-plugins-2.0.2.tar.gz
tar xzvf nagios-plugins-2.0.2.tar.gz
cd nagios-plugins-2.0.2
cmd2="./configure --with-nagios-user=nagios --with-nagios-group=nagios"
$cmd2
make
make install
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
chkconfig --add nagios
chkconfig nagios on
service nagios start
else
echo "nagios-plugins installed"
fi

# cacti and nagios

path_ndo2db=/home/nagios/ndoutils-1.4b7.tar.gz
if [ ! -f $path_ndo2db ];then
cd /home/nagios
wget http://jaist.dl.sourceforge.net/project/nagios/ndoutils-1.x/ndoutils-1.4b7/ndoutils-1.4b7.tar.gz
tar zxvf ndoutils-1.4b7.tar.gz
cd ndoutils-1.4b7
cmd3="./configure --prefix=/usr/local/nagios/ --with-mysql-inc=/usr/include/mysql --with-mysql-lib=/usr/lib64/mysql --enable-mysql --disable-pgsql --with-ndo2db-user=nagios --with-ndo2db-group=nagios"
$cmd3
make
cd db
./installdb -u cactier -p 123456 -h localhost -d cactidb
cd /home/nagios/ndoutils-1.4b7
#cmd4="cp src/{ndomod-3x.o,ndo2db-3x,log2ndo,file2sock} /usr/local/nagios/bin"
#$cmd4
cp /home/nagios/ndoutils-1.4b7/src/ndomod-3x.o /usr/local/nagios/bin/
cp /home/nagios/ndoutils-1.4b7/src/ndo2db-3x /usr/local/nagios/bin/
cp /home/nagios/ndoutils-1.4b7/src/log2ndo /usr/local/nagios/bin/
cp /home/nagios/ndoutils-1.4b7/src/file2sock /usr/local/nagios/bin/
cp /home/nagios/ndoutils-1.4b7/config/ndomod.cfg /usr/local/nagios/etc/ndomod.cfg
cp /home/nagios/ndoutils-1.4b7/config/ndo2db.cfg /usr/local/nagios/etc/ndo2db.cfg
cd /usr/local/nagios/etc/
chown nagios:nagios ndo2db.cfg ndomod.cfg
chmod 664 ndo2db.cfg ndomod.cfg
cd /usr/local/nagios/bin
mv ndo2db-3x ndo2db
mv ndomod-3x.o ndomod.o
chown nagios:nagios *
else
echo "ndoutils installed"
fi

path_nagios_cfg=/usr/local/nagios/etc/nagios.cfg
echo "original:"
echo ""
sed -n -e "247p" $path_nagios_cfg

sed -i "247c broker_module=/usr/local/nagios/bin/ndomod.o config_file=/usr/local/nagios/etc/ndomod.cfg" $path_nagios_cfg

echo "Now:"
echo ""
sed -n -e "247p" $path_nagios_cfg

path_ndo2db_cfg=/usr/local/nagios/etc/ndo2db.cfg
echo "original:"
echo ""
sed -n -e "24p" $path_ndo2db_cfg
sed -n -e "25p" $path_ndo2db_cfg
sed -n -e "62p" $path_ndo2db_cfg
sed -n -e "79p" $path_ndo2db_cfg
sed -n -e "88p" $path_ndo2db_cfg
sed -n -e "97p" $path_ndo2db_cfg
sed -n -e "98p" $path_ndo2db_cfg
sed -n -e "138p" $path_ndo2db_cfg

sed -i "24c#socket_type=unix" $path_ndo2db_cfg
sed -i "25csocket_type=tcp" $path_ndo2db_cfg
sed -i "62cdb_host=127.0.0.1" $path_ndo2db_cfg
sed -i "79cdb_name=cactidb" $path_ndo2db_cfg
sed -i "88cdb_prefix=npc_" $path_ndo2db_cfg
sed -i "97cdb_user=cactier" $path_ndo2db_cfg
sed -i "98cdb_pass=123456" $path_ndo2db_cfg
sed -i "138cdebug_devel=1" $path_ndo2db_cfg

echo "Now:"
echo ""
sed -n -e "24p" $path_ndo2db_cfg
sed -n -e "25p" $path_ndo2db_cfg 
sed -n -e "62p" $path_ndo2db_cfg
sed -n -e "79p" $path_ndo2db_cfg
sed -n -e "88p" $path_ndo2db_cfg
sed -n -e "97p" $path_ndo2db_cfg
sed -n -e "98p" $path_ndo2db_cfg
sed -n -e "138p" $path_ndo2db_cfg

path_ndomod_cfg=/usr/local/nagios/etc/ndomod.cfg
echo "original:"
echo ""

sed -n -e "25p" $path_ndomod_cfg
sed -n -e "26p" $path_ndomod_cfg
sed -n -e "39p" $path_ndomod_cfg
sed -n -e "40p" $path_ndomod_cfg

sed -i "25coutput_type=tcpsocket" $path_ndomod_cfg
sed -i "26c#output_type=unixsocket" $path_ndomod_cfg
sed -i "39coutput=127.0.0.1" $path_ndomod_cfg
sed -i "40c#output=/usr/local/nagios/var/ndo.sock" $path_ndomod_cfg
echo "Now:"
echo ""
sed -n -e "25p" $path_ndomod_cfg
sed -n -e "26p" $path_ndomod_cfg
sed -n -e "39p" $path_ndomod_cfg
sed -n -e "40p" $path_ndomod_cfg
path_initd_ndo2db=/etc/init.d/ndo2db
if [ ! -f $path_initd_ndo2db ];then
echo '#!/bin/bash
# description: NRPE DAEMON
ndo2db=/usr/local/nagios/bin/ndo2db
ndo2dbconf=/usr/local/nagios/etc/ndo2db.cfg
case "$1" in
 start)
  echo -n "Starting ndo2db daemon..."
  $ndo2db -c $ndo2dbconf
  echo " done."
  ;;
 stop)
  echo -n "Stopping ndo2db daemon..."
  pkill -u nagios ndo2db
  echo " done."
 ;;
 restart)
  $0 stop
  sleep 2
  $0 start
  ;;
 *)
  echo "Usage: $0 start|stop|restart"
  ;;
 esac
exit 0' > /etc/init.d/ndo2db
chmod +x /etc/init.d/ndo2db
service ndo2db restart 
chkconfig --add ndo2db
chkconfig ndo2db on
else
echo "ndo2db is open himself"
fi

cd /home/nagios
path_npc=/home/nagios/npc.tar.gz
if [ ! -f $path_npc ];then
wget http://www.cactifans.org/plugins/npc.tar.gz
tar zxvf npc.tar.gz
mv npc /var/www/html/cacti/plugins/
else
echo "npc installed"
fi
echo "original:"
sed -n -e "40p" /var/www/html/cacti/include/config.php
npccmd="'npc'"
plugins='$plugins'
sed -i "40c$plugins[] = $npccmd;" /var/www/html/cacti/include/config.php
echo "Now:"
sed -n -e "40p" /var/www/html/cacti/include/config.php


service mysqld restart
service httpd restart
service ndo2db restart
service nagios restart

