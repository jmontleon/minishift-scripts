## Scripts to help set up minishift
 * ensure you have origin and origin-clients installed
 * Copy config.example to config and change options in the file
 * By default it looks for minishift in a folder side by side with minishift-scripts
 * Use minishift-create.sh to create your minishift
 * use other scripts to manage it
 * For versions less than v1.5.0 we will set up hostPath pv's similar to the way newer versions do
 * Most of the rest of the scripts are just wrappers with the exception of minishift-stop.sh. I have had /var/lib/docker corrupt several times. Sync'ing the disk before stopping seems to help with this situation.
 * admin is given the custer-admin cluster-role for now. This is to enable ansibleapp to autocreate projects until a better solution is derived
 * oadm policy add-scc-to-group anyuid system:authenticated in order to run as user specified in Dockerfile
