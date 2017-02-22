#!/bin/bash
source config

# boot2misery^Wboot2docker likes to corrupt /var/lib/docker
${MINISHIFT} ssh -- sync 
${MINISHIFT} stop
