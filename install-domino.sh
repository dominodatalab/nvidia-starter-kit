#!/bin/bash

set -x

HOSTNAME=$1
QUAY_USERNAME=$2
QUAY_PASSWORD=$(echo "$3" | sed 's/\//\\\//g')
NAME="domino-nvidia-starter-kit"

# generate certificate and install into cluster as TLS secret default/crt1
kubectl get secrets | tee /dev/tty | grep -q "crt1"
if [ $? -ne 0 ] ; then
        openssl req -x509 -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -subj "/CN=$HOSTNAME"
        kubectl create secret tls crt1 --key="key.pem" --cert="cert.pem"
fi

# create and label domino namespaces
kubectl get ns | tee /dev/tty | grep -q "domino"
if [ $? -ne 0 ] ; then
        kubectl create ns domino-platform
        kubectl label ns domino-platform domino-platform=true
        kubectl create ns domino-compute
        kubectl label ns domino-compute domino-compute=true
        kubectl create ns domino-system
fi

# label node
kubectl label node $(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}') dominodatalab.com/node-pool=default-gpu --overwrite
kubectl label node $(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}') domino/build-node=true --overwrite

# create hostpath directories and make them globally readable and writable
sudo mkdir -p /domino
sudo mkdir -p /domino/docker
sudo mkdir -p /domino/shared
sudo mkdir -p /domino/git
sudo mkdir -p /domino/blobs
sudo chmod -R 777 /domino/*

# create manual hostpath PVs and PVCs for domino shared storage
kubectl get pv | tee /dev/tty | grep -q "blob"
if [ $? -ne 0 ] ; then
        kubectl apply -f domino-volumes.yaml
fi

# inject hostname and credentials into template to produce installer configuration file
cat domino-template.yaml | sed -e "s/\${HOSTNAME}/$HOSTNAME/" | sed -e "s/\${NAME}/$NAME/" | sed -e "s/\${QUAY_USERNAME}/$QUAY_USERNAME/" | sed -e "s/\${QUAY_PASSWORD}/$QUAY_PASSWORD/" > domino.yaml

# install domino
sudo docker login quay.io -u $QUAY_USERNAME -p $QUAY_PASSWORD
sudo docker run --rm -v $(pwd):/install -v ~/.kube:/kube -e KUBECONFIG=/kube/config --network='host' quay.io/domino/fleetcommand-agent:latest run --file /install/domino.yaml
