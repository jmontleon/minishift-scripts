#!/bin/bash

# boot2misery^Wboot2docker likes to corrupt /var/lib/docker
../minishift/minishift ssh -- sync \
&& ../minishift/minishift stop
