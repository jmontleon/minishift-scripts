#!/bin/bash
source config

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
  echo "Change ADD_NFS to false or run as root"
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

oc login -u system:admin
oadm policy add-scc-to-group anyuid system:authenticated
oadm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin

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

if ${ADD_NFS}; then
source configure-nfs.sh
fi
