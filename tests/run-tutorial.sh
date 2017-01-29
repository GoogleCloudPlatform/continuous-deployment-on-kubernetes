#!/bin/bash -xe
gcloud compute networks create jenkins --mode auto
gcloud container clusters create jenkins-cd \
        --network jenkins \
        --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"
gcloud container clusters list
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info
gcloud compute images create jenkins-home-image --source-uri https://storage.googleapis.com/solutions-public-assets/jenkins-cd/jenkins-home-v3.tar.gz
gcloud compute disks create jenkins-home --image jenkins-home-image --zone $zone
PASSWORD=`openssl rand -base64 15`; echo "Your password is $PASSWORD"; sed -i.bak s#CHANGE_ME#$PASSWORD# jenkins/k8s/options
kubectl create ns jenkins
kubectl create secret generic jenkins --from-file=jenkins/k8s/options --namespace=jenkins
kubectl apply -f jenkins/k8s/
kubectl get pods --namespace jenkins
kubectl get svc --namespace jenkins
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=jenkins/O=jenkins"
kubectl create secret generic tls --from-file=/tmp/tls.crt --from-file=/tmp/tls.key --namespace jenkins
kubectl apply -f jenkins/k8s/lb/ingress.yaml
for i in `seq 1 5`;do kubectl describe ingress jenkins --namespace jenkins; sleep 60;done

kubectl get ingress --namespace jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}' jenkins
kubectl describe ingress --namespace=jenkins jenkins | grep backends | grep HEALTHY
