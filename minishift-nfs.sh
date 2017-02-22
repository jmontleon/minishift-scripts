#!/bin/bash

../minishift/minishift start
../minishift/minishift ssh -- mkdir -p origin \
&& ../minishift/minishift ssh -- "echo FROM openshift/origin:v1.4.1 > origin/Dockerfile" \
&& ../minishift/minishift ssh -- "echo RUN yum -y install nfs-utils >> origin/Dockerfile" \
&& ../minishift/minishift ssh -- docker build -t openshift/origin:v1.4.1 origin
../minishift/minishift ssh -- sync \
&& ../minishift/minishift stop
../minishift/minishift start
