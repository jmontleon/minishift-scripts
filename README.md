## Scripts to help set up minishift
 * Modify options in the config file
 * If you want to set up NFS you can either do so on the same host by saying ADD_NFS=true or on a separate host manuall or with the configure-nfs.sh script
 * If you set up nfs either way you can configure pvs automatically. PV_IP might need to be modified in particular.
 * Most of the rest of the scripts are the same with the exception of minishift-stop.sh. I have had /var/lib/docker corrupt several times. Sync'ing the disk before stopping seems to help with this situation.
 * admin is given the custer-admin cluster-role for now. This is to enable ansibleapp to autocreate projects until a better solution is derived
 * oadm policy add-scc-to-group anyuid system:authenticated in order to run as user specified in Dockerfile
