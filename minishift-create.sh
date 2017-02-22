#!/bin/bash
source config

echo Minishift is $MINISHIFT

### Things that may break if you change them:
if [ ! -f ${MINISHIFT} ]; then
  echo "minishift not found. Change MINISHIFT and try again"
  exit 1
elif ! rpm -q origin 2>&1 > /dev/null; then 
  echo "Install origin: dnf -y install origin"; 
  exit 2
elif ! rpm -q origin-clients 2>&1 > /dev/null; then 
  echo "Install origin: dnf -y install origin-clients"; 
  exit 3
elif ${ADD_NFS} && $(id -u) > 0; then
  echo "Change ADD_PVS and ADD_NFS to false or run as root"
  exit 4
fi

${MINISHIFT} config set cpus ${CPUS} > /dev/null
${MINISHIFT} config set memory ${MEMORY} > /dev/null
${MINISHIFT} config set disk-size ${DISK_SIZE} > /dev/null
${MINISHIFT} start
${MINISHIFT} ssh -- mkdir -p origin
${MINISHIFT} ssh -- "echo FROM openshift/origin:v1.4.1 > origin/Dockerfile"
${MINISHIFT} ssh -- "echo RUN yum -y install nfs-utils >> origin/Dockerfile"
${MINISHIFT} ssh -- docker build -t openshift/origin:v1.4.1 origin
${MINISHIFT} ssh -- sync
${MINISHIFT} stop
sleep 5
${MINISHIFT} start

if ${ADD_NFS}; then
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
fi

if ${ADD_PVS}; then
  for i in $(seq -w 1 $NUM_PVS); do
    PART_A="apiVersion: v1\nkind: PersistentVolume\nmetadata:\n  name: pv${i}"
    PART_B="\nspec:\n  accessModes:\n  - ReadWriteOnce\n  - ReadWriteMany\n  "
    PART_C="capacity:\n    storage: ${PV_SIZE}Gi\n  nfs:\n    path: /nfsvolum"
    PART_D="es/pv${i}\n    server: ${PV_IP}\n  persistentVolumeReclaimPolicy:"
    PART_E=" Recycle\n"
    echo -ne "${PART_A}${PART_B}${PART_C}${PART_D}${PART_E}" | oc create -f -
  done
fi

oc login -u system:admin
add-scc-to-group anyuid system:authenticated
oadm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
