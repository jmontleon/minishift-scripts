#!/bin/bash
source config

### Things that may break if you change them:
if [ ! -f ${MINISHIFT} ]; then
  echo "minishift not found. Change MINISHIFT and try again"
  exit 1
elif ! rpm -q origin 2>&1 > /dev/null; then 
  echo "Install origin: dnf -y install origin origin-clients"
  exit 2
elif ! rpm -q origin-clients 2>&1 > /dev/null; then 
  echo "Install origin: dnf -y install origin origin-clients"
  exit 3
fi

${MINISHIFT} config set cpus ${CPUS} > /dev/null
${MINISHIFT} config set memory ${MEMORY} > /dev/null
${MINISHIFT} config set disk-size ${DISK_SIZE} > /dev/null
${MINISHIFT} start  --openshift-version "${ORIGIN_VERSION}"

oc login -u system:admin

#Let any uid run containers with user specified by container
oadm policy add-scc-to-group anyuid system:authenticated

#Add cluster-admin role to admin
oadm policy add-cluster-role-to-user cluster-admin admin

#Let any user use hostPath mounts
oc adm policy add-scc-to-group hostmount-anyuid system:authenticated

oc login -u admin -p admin

path=/var/lib/origin/openshift.local.pv/pv
if [[ "${ORIGIN_VERSION}" < v1.5.0 ]] ; then
  ${MINISHIFT} ssh -- "for i in \$(seq -w 1 0100);do mkdir -p ${path}\${i};done"
  for i in $(seq -w 1 0100); do
    PART_A="apiVersion: v1\nkind: PersistentVolume\nmetadata:\n  name: pv${i}"
    PART_B="\nspec:\n  accessModes:\n  - ReadWriteOnce\n  - ReadWriteMany\n  c"
    PART_C="apacity:\n    storage: 100Gi\n  hostPath:\n    path: ${path}${i}"
    PART_D="\n  persistentVolumeReclaimPolicy: Recycle\n"
    echo -ne "${PART_A}${PART_B}${PART_C}${PART_D}" | oc create -f -
  done
fi

#1.5.0+ Spawns a container to create pv's and does not wait, so we need to wait
sleep 30
${MINISHIFT} ssh -- "sudo chmod 777 ${path}*;done"
