#!/bin/bash -xe
gcloud container clusters get-credentials jenkins-cd
kubectl cluster-info

cd sample-app
kubectl delete ns production  --grace-period=0 || true
kubectl create ns production
kubectl --namespace=production apply -f k8s/production
kubectl --namespace=production apply -f k8s/canary
kubectl --namespace=production apply -f k8s/services
kubectl --namespace=production scale deployment gceme-frontend-production --replicas=4

for i in `seq 1 5`;do kubectl --namespace=production get service gceme-frontend; sleep 60;done

export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services gceme-frontend)
curl http://$FRONTEND_SERVICE_IP/version | grep v1.0.0