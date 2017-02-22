#!/bin/bash
source config

dnf -y install nfs-utils iptables-services

for i in $(seq -w 1 $NUM_PVS); do
  mkdir -p /nfsvolumes/pv${i}
  chmod 777 /nfsvolumes/pv${i}
done

#This only works on a non-empty file so we check after and add it if it doesn't leave or update it
sed -i '/^\/nfsvolumes /{h;s/\ .*/ *(rw,insecure_locks,root_squash)/};${x;/^$/{s//\/nfsvolumes *(rw,insecure_locks,root_squash)/;H};x}' /etc/exports
if grep -q -v -w /nfsvolumes /etc/exports; then
  echo "/nfsvolumes *(rw,insecure_locks,root_squash)" /etc/exports
fi

systemctl stop firewalld
systemctl disable firewalld
systemctl enable ip6tables
systemctl enable iptables
systemctl enable nfs-server
systemctl start ip6tables
systemctl start iptables
systemctl start nfs-server
exportfs -ar

if ! /usr/sbin/iptables -C INPUT -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 20049 -j ACCEPT >/dev/null  2>&1; then
  /usr/sbin/iptables -I INPUT 4 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 20049 -j ACCEPT
fi
if ! /usr/sbin/iptables -C INPUT -p udp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 20049 -j ACCEPT >/dev/null  2>&1; then
  /usr/sbin/iptables -I INPUT 4 -p udp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 20049 -j ACCEPT
fi
if ! /usr/sbin/iptables -C INPUT -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 111 -j ACCEPT >/dev/null  2>&1; then
  /usr/sbin/iptables -I INPUT 4 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 111 -j ACCEPT
fi
if ! /usr/sbin/iptables -C INPUT -p udp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 111 -j ACCEPT >/dev/null  2>&1; then
  /usr/sbin/iptables -I INPUT 4 -p udp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 111 -j ACCEPT
fi
if ! /usr/sbin/iptables -C INPUT -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 2049 -j ACCEPT >/dev/null  2>&1; then
  /usr/sbin/iptables -I INPUT 4 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 2049 -j ACCEPT
fi
if ! /usr/sbin/iptables -C INPUT -p udp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 2049 -j ACCEPT >/dev/null  2>&1; then
  /usr/sbin/iptables -I INPUT 4 -p udp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 2049 -j ACCEPT
fi
