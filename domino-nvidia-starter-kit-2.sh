#!/bin/bash

### BEGIN INIT INFO
# Provides:          domino-nvidia-starter-kit-install
# Required-Start:    $all
# Required-Stop:
# Default-Start:     5
# Default-Stop:
# Short-Description: Domino Nvidia Starter Kit Install Pt2
### END INIT INFO

echo "Deleting self (maybe)..."
if [ -f /etc/init.d/domino-nvidia-starter-kit-boot.sh ] ; then
        sudo rm /etc/init.d/domino-nvidia-starter-kit-2.sh
        sudo update-rc.d -f domino-nvidia-starter-kit-2.sh remove
        exit 0
fi

echo "Relocating to script home directory..."
DIR=${DIR}
cd $DIR

echo "Resuming Kubernetes playbook..."
cd ../deepops
sudo -u ubuntu ansible-playbook -l k8s-cluster playbooks/k8s-cluster.yml | tee /dev/tty | grep -q "failed=0"
if [ $? -ne 0 ] ; then
        echo "Issue running playbook"
        exit -1
fi

echo "Enabling MIG..."
sudo nvidia-smi -mig 1

echo "Waiting for NVIDIA device plugin. This can take 5 minutes..."
sleep 2m

sudo -u ubuntu ansible-playbook playbooks/nvidia-software/nvidia-mig.yml | tee /dev/tty | grep -q "failed=0"
if [ $? -eq 0 ] ; then
        cd ../domino-nvidia-starter-kit
        cp -n domino-nvidia-starter-kit-boot.sh domino-nvidia-starter-kit-boot.sh_backup
        cat domino-nvidia-starter-kit-boot.sh_backup | sed -e "s@\${DIR}@$DIR@" > domino-nvidia-starter-kit-boot.sh
        
        sudo cp domino-nvidia-starter-kit-boot.sh /etc/init.d/domino-nvidia-starter-kit-boot.sh
        sudo chmod 755 /etc/init.d/domino-nvidia-starter-kit-boot.sh
        sudo chown root:root /etc/init.d/domino-nvidia-starter-kit-boot.sh
        
        sudo update-rc.d domino-nvidia-starter-kit-boot.sh defaults
        sudo update-rc.d domino-nvidia-starter-kit-boot.sh enable
        
        sudo reboot
else
        echo "Issue running playbook"
        exit -1
fi
