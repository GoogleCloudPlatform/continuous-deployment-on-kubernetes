#!/bin/bash -xe
export PROJECT_ID=jenkins-gke-`date +%s`
export ZONE=us-east1-d
echo y | gcloud components update
echo y | gcloud components install kubectl
#echo y | gcloud components install alpha
#gcloud alpha projects create ${PROJECT_ID}
#gcloud alpha billing accounts projects link --account-id ${BILLING_ACCOUNT_ID} ${PROJECT_ID}
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${ZONE}

#sleep 600 # Wait for project to enable APIs, should probably poll

gcloud compute networks create jenkins --mode auto

gcloud container clusters create jenkins-cd --network jenkins --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"

gcloud container clusters list
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info
gcloud compute images create jenkins-home-image --source-uri https://storage.googleapis.com/solutions-public-assets/jenkins-cd/jenkins-home.tar.gz
gcloud compute disks create jenkins-home --image jenkins-home-image --zone us-east1-d

export PASSWORD=`openssl rand -base64 15`
echo "Your password is $PASSWORD"
sed -i.bak s#/CHANGE_ME#$PASSWORD# jenkins/k8s/options
kubectl create ns jenkins
kubectl create secret generic jenkins --from-file=jenkins/k8s/options --namespace=jenkins
kubectl apply -f jenkins/k8s/
kubectl get pods --namespace jenkins
export NODE_PORT=$(kubectl get --namespace=jenkins -o jsonpath="{.spec.ports[0].nodePort}" services jenkins-ui)
gcloud compute firewall-rules create allow-130-211-0-0-22 --source-ranges 130.211.0.0/22 --allow tcp:$NODE_PORT --network jenkins
kubectl get pods --namespace jenkins
kubectl get svc --namespace jenkins
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=jenkins/O=jenkins"
kubectl create secret generic tls --from-file=/tmp/tls.crt --from-file=/tmp/tls.key --namespace jenkins
kubectl apply -f jenkins/k8s/lb/ingress.yaml
kubectl describe ingress jenkins --namespace jenkins

sleep 360
export INGRESS_IP=$(kubectl get --namespace=jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}" ingress jenkins)
curl https://${INGRESS_IP}

#echo y | gcloud projects delete ${PROJECT_ID}