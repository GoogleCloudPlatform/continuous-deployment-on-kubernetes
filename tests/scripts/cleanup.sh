#!/bin/bash -xe
printf "y\n" | gcloud container clusters delete jenkins-cd || true
printf "y\n" | gcloud compute images delete jenkins-home-image || true
printf "y\n" | gcloud compute disks delete jenkins-home || true
for rule in $(gcloud compute firewall-rules list --filter network~jenkins --format='value(name)');do
  printf "y\n" | gcloud compute firewall-rules delete $rule || true
done
printf "y\n" | gcloud compute networks delete jenkins || true
for rule in $(gcloud compute forwarding-rules list  --regexp '.*jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute forwarding-rules delete $rule --global
done
for address in $(gcloud compute addresses list --regexp '.*-jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute addresses delete $address --global
done
for proxy in $(gcloud compute target-https-proxies list  --regexp '.*jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute target-https-proxies delete $proxy
done
for cert in $(gcloud compute ssl-certificates list --regexp 'k8s-ssl-jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute ssl-certificates delete $cert
done
for target in $(gcloud compute target-pools list --regexp '.*-jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute target-pools delete $target
done
for target in $(gcloud compute target-http-proxies list --regexp '.*-jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute target-http-proxies delete $target
done
for url in $(gcloud compute url-maps list --regexp '.*-jenkins-jenkins.*'  --format='value(name)');do
  printf "y\n" | gcloud compute url-maps delete $url
done
