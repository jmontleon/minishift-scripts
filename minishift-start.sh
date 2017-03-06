#!/bin/bash
source config

${MINISHIFT} start

path=/var/lib/origin/openshift.local.pv/pv
${MINISHIFT} ssh -- "for i in \$(seq -w 1 0100);do mkdir -p ${path}\${i};done"
${MINISHIFT} ssh -- "sudo chmod 777 ${path}*;done"
