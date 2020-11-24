#!/bin/bash

set -ex

HOSTNAME=$1
QUAY_USERNAME=$2
QUAY_PASSWORD=$3
NAME="nvidia"

# generate certificate and install into cluster as TLS secret default/crt1
openssl req -x509 -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -subj "/CN=$HOSTNAME"
kubectl create secret tls crt1 --key="key.pem" --cert="cert.pem"

# create and label domino namespaces
kubectl create ns domino-platform
kubectl label ns domino-platform domino-platform=true
kubectl create ns domino-compute
kubectl label ns domino-compute domino-compute=true
kubectl create ns domino-system

# label node
kubectl label node $(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}') dominodatalab.com/node-pool=default-gpu
kubectl label node $(kubectl get nodes -o=jsonpath='{.items[0].metadata.name}') domino/build-node=true

# create hostpath directories and make them globally readable and writable
mkdir /domino
mkdir /domino/docker
mkdir /domino/shared
mkdir /domino/git
mkdir /domino/blobs
chmod 777 /domino*

# create manual hostpath PVs and PVCs for domino shared storage
kubectl apply -f domino-volumes.yaml

# inject hostname and credentials into template to produce installer configuration file
cat template.yaml | sed -e “s/\${HOSTNAME}/$HOSTNAME/“ | sed -e “s/\${NAME}/$NAME/“ | sed -e “s/\${QUAY_USERNAME}/$QUAY_USERNAME/“ | sed -e “s/\${QUAY_PASSWORD}/$QUAY_PASSWORD/“ >> domino.yaml

# install domino
sudo docker run --rm -v $(pwd):/install -v ~/.kube:/kube -e KUBECONFIG=/kube/config --network='host' quay.io/domino/fleetcommand-agent:latest run --file /install/domino.yaml
