#!/bin/bash
set -e
patching(){
    apt-get update && apt-get upgrade -y;
	apt-get install --allow-unauthenticated software-properties-common -y
	apt-get install make gcc -y
};
patching;

cd ~
wget --no-check-certificate https://github.com/z3APA3A/3proxy/archive/0.8.12.tar.gz
tar xzf 0.8.12.tar.gz
cd ~/3proxy-0.8.12
make -f Makefile.Linux
mkdir /etc/3proxy
cd ~/3proxy-0.8.12/src
cp 3proxy /usr/bin/
adduser --system --no-create-home --disabled-login --group proxy3

touch /etc/3proxy/3proxy.cfg

echo "
setgid $(id -g proxy3)
setuid $(id -u proxy3)
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
users $/etc/3proxy/.proxyauth
daemon
auth cache strong
proxy -n -p40000 -a
socks -p50000" >> /etc/3proxy/3proxy.cfg

#https proxy на 40000 порту, socks5 на 50000

touch /etc/3proxy/.proxyauth

echo "user:CL:password" >> /etc/3proxy/.proxyauth	#логин и пароль по умолчанию

chown proxy3:proxy3 -R /etc/3proxy
chown proxy3:proxy3 /usr/bin/3proxy
chmod 444 /etc/3proxy/3proxy.cfg
chmod 400 /etc/3proxy/.proxyauth

mkdir /var/log/3proxy
chown proxy3:proxy3 /var/log/3proxy

touch /etc/init.d/3proxy

echo '
#!/bin/sh
#
### BEGIN INIT INFO
# Provides: 3Proxy
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Initialize 3proxy server
# Description: starts 3proxy
### END INIT INFO

case "$1" in
 start)
 echo Starting 3Proxy

 /usr/bin/3proxy /etc/3proxy/3proxy.cfg
 ;;

 stop)
 echo Stopping 3Proxy
 /usr/bin/killall 3proxy
 ;;

 restart|reload)
 echo Reloading 3Proxy
 /usr/bin/killall -s USR1 3proxy
 ;;
 *)
 echo Usage: \$0 "{start|stop|restart}"
 exit 1
esac
exit 0' >> /etc/init.d/3proxy

chmod +x /etc/init.d/3proxy

update-rc.d 3proxy defaults

/etc/init.d/3proxy start

iptables -I INPUT -p tcp -m tcp --dport 40000 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 50000 -j ACCEPT
iptables -I INPUT -p udp -m udp --dport 50000 -j ACCEPT
