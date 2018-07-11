#!/bin/bash -xe
gcloud compute networks create jenkins --subnet-mode auto
gcloud container clusters create jenkins-cd \
        --machine-type n1-standard-2 \
        --num-nodes 2 \
        --network jenkins \
        --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"
gcloud container clusters list
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info

HELM_VERSION=2.6.1
wget https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-linux-amd64.tar.gz
tar zxfv helm-v$HELM_VERSION-linux-amd64.tar.gz
cp linux-amd64/helm .
./helm init
./helm repo update
# Give tiller a chance to start up
# TODO: Change this to polling
sleep 180
./helm version | grep $HELM_VERSION

./helm install -n cd stable/jenkins -f jenkins/config.yaml --version 0.8.9

for i in `seq 1 5`;do kubectl get pods; sleep 60;done

kubectl get pods -l app=cd-jenkins | grep Running

# Cleanup resources
./helm delete --purge cd
sleep 120
