#!/bin/bash
source config

### Things that may break if you change them:
if [ ! -f ${MINISHIFT} ]; then
  echo "minishift not found. Change MINISHIFT and try again"
  exit 1
fi
export MINISHIFT_GITHUB_API_TOKEN="${GH_TOKEN}"
${MINISHIFT} config set cpus ${CPUS} > /dev/null
${MINISHIFT} config set memory ${MEMORY} > /dev/null
${MINISHIFT} config set disk-size ${DISK_SIZE} > /dev/null
MINISHIFT_ENABLE_EXPERIMENTAL=y ${MINISHIFT} start  --openshift-version "${ORIGIN_VERSION}" --extra-clusterup-flags='--service-catalog'
${MINISHIFT} ssh -- "while ! echo exit | nc localhost 8443; do sleep 10; done"
oc login -u system:admin
oc adm policy add-scc-to-group anyuid system:authenticated
oc adm policy add-cluster-role-to-user cluster-admin admin
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

if [[ "${ORIGIN_VERSION}" < v1.5.0 ]] ; then
  ${MINISHIFT} ssh -- "for i in \$(seq -w 1 0100);do chmod 777 ${path}\${i};done"
else
  path=/var/lib/minishift/openshift.local.pv/pv
  ${MINISHIFT} ssh -- "while [ ! -d ${path}0100 ]; do sleep 2; done"
  ${MINISHIFT} ssh -- "for i in \$(seq -w 1 0100);do sudo chmod 777 ${path}\${i};done"
fi

${MINISHIFT} addon apply ansible-service-broker
