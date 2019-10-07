#!/bin/bash -xe
gcloud compute networks create jenkins --subnet-mode auto
gcloud container clusters create jenkins-cd \
        --machine-type n1-standard-2 \
        --num-nodes 2 \
        --network jenkins \
        --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw" \
        --cluster-version 1.12
gcloud container clusters list
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info

HELM_VERSION=2.9.1
wget https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-linux-amd64.tar.gz
tar zxfv helm-v$HELM_VERSION-linux-amd64.tar.gz
cp linux-amd64/helm .

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

./helm init --service-account=tiller
./helm update

# Give tiller a chance to start up
until ./helm version; do sleep 10;done

./helm install -n cd stable/jenkins -f jenkins/values.yaml --version 1.2.2 --wait

for i in `seq 1 5`;do kubectl get pods; sleep 60;done

until kubectl get pods -l app=cd-jenkins | grep Running; do sleep 10;done

# Cleanup resources
./helm delete --purge cd
