#!/bin/bash

### CHECK START CONDITION
if false ; then
        read -p "It looks like these scripts have previously been executed and running them again may change some of the configuration on this machine. Are you sure you want to continue? " -n 1 -r
        echo # Move to a new line
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
                exit -1
        fi
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Installing pip..."
sudo apt update
sudo apt -y install python-pip

echo "Cloning NVIDIA/deepops repository..."
cd ..
if [ ! -d "deepops" ] ; then
        git clone --depth 1 --branch 20.12 https://github.com/NVIDIA/deepops.git 
fi
cd deepops

echo "Setting up Ansible and dependencies by running the DeepOps setup script..."
bash ./scripts/setup.sh

echo "Editing the Ansible configuration file ansible.cfg to set up running the playbook against the local host..."
cp -n ansible.cfg ansible.cfg_backup
cat ansible.cfg_backup | sed '/^\[defaults\]$/a transport = local' > ansible.cfg

echo "Replacing the default DeepOps playbook inventory file config/inventory with the local-only inventory..."
cp -n config/inventory config/inventory_backup
cp ../nvidia-starter-kit/inventory_template config/inventory

echo "Updating the Multi-instance GPU (MIG) strategy to 'single' mode..."
cp -n config/group_vars/k8s-cluster.yml config/group_vars/k8s-cluster.yml_backup
cat config/group_vars/k8s-cluster.yml_backup | sed 's/^k8s_gpu_mig_strategy.*/k8s_gpu_mig_strategy: "single"/g' > config/group_vars/k8s-cluster.yml

echo "Validating Ansible configuration..."
ansible all -m raw -a "hostname" | tee /dev/tty | grep -q "failed=0"
if [ $? -ne 0 ] ; then
        echo "Issue with ansible configuration"
        exit -1
fi

echo "Running the Kubernetes playbook..."
ansible-playbook -l k8s-cluster playbooks/k8s-cluster.yml | tee /dev/tty | grep -q "msg: Running reboot with local connection would reboot the control node"
if [ $? -eq 0 ] ; then
        cd ../nvidia-starter-kit
        cp -n domino-nvidia-starter-kit-2.sh domino-nvidia-starter-kit-2.sh_backup
        cat domino-nvidia-starter-kit-2.sh_backup | sed -e "s@\=\${DIR}@\=$DIR@" > domino-nvidia-starter-kit-2.sh

        sudo cp domino-nvidia-starter-kit-2.sh /etc/init.d/domino-nvidia-starter-kit-2.sh
        sudo chmod 755 /etc/init.d/domino-nvidia-starter-kit-2.sh
        sudo chown root:root /etc/init.d/domino-nvidia-starter-kit-2.sh

        sudo update-rc.d domino-nvidia-starter-kit-2.sh defaults
        sudo update-rc.d domino-nvidia-starter-kit-2.sh enable

        sudo reboot
else
        echo "Issue running playbook"
        exit -1
fi
