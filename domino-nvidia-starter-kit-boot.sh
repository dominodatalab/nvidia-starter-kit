#!/bin/bash

### BEGIN INIT INFO
# Provides:          domino-nvidia-starter-kit-boot
# Required-Start:    $all
# Required-Stop:
# Default-Start:     5
# Default-Stop:
# Short-Description: Domino Nvidia Starter Kit Boot
### END INIT INFO

echo "Relocating to script home directory..."
DIR=${DIR}
cd $DIR

echo "Provisioning MIG resources..."
sudo nvidia-smi mig -cgi 19,19,19,19,19,19,19 -C

echo "Running the device plugin and feature discovery playbooks to restart the Kubernetes GPU controllers and detect the new virtual devices..."
cd ../deepops
sudo -u ubuntu ansible-playbook playbooks/k8s-cluster/nvidia-k8s-gpu-device-plugin.yml playbooks/k8s-cluster/nvidia-k8s-gpu-feature-discovery.yml | tee /dev/tty | grep -q "failed=0"
if [ $? -ne 0 ] ; then
        echo "Issue running playbook"
        exit -1
fi
