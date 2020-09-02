#!/bin/bash
set -e
patching(){
    apt-get update && apt-get upgrade -y;
	apt-get install --allow-unauthenticated software-properties-common -y
	apt-get install wget make gcc -y
};
patching;

cd ~
git clone https://github.com/z3apa3a/3proxy
cd 3proxy
ln -s Makefile.Linux Makefile
make
sudo make install

touch /etc/3proxy/conf/3proxy.cfg

echo "
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
users $/conf/passwd
daemon
auth cache strong
proxy -n -a -p50000
socks -p50001" >> /etc/3proxy/conf/3proxy.cfg
#https proxy на 50000 порту, socks5 на 50001

touch /etc/3proxy/conf/passwd

echo "user:CL:password" >> /etc/3proxy/conf/passwd	#логин и пароль по умолчанию

service 3proxy restart
