#!/bin/bash -xe

case "$OSTYPE" in
  darwin*)  OS="darwin" ENDIAN="amd64" ;;
  linux*)   OS="linux" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

if [ $OS = "linux" ] && [ `getconf LONG_BIT` == 64 ]; then
        ENDIAN="amd64"
elif [ `getconf LONG_BIT` == 32 ]; then
        ENDIAN="386"
else
        #assume amd64"
        ENDIAN="amd64"
fi


gcloud compute networks create jenkins --mode auto
gcloud container clusters create jenkins-cd \
        --machine-type n1-standard-2 \
        --num-nodes 2 \
        --network jenkins \
        --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"
gcloud container clusters list
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info

HELM_VERSION=2.6.1
wget https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-$OS-$ENDIAN.tar.gz
tar zxfv helm-v$HELM_VERSION-$OS-$ENDIAN.tar.gz
cp $OS-$ENDIAN/helm .
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
