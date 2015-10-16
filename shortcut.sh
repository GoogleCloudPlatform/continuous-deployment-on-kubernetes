# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#! /bin/bash
gcloud container clusters create gtc \
  --scopes https://www.googleapis.com/auth/cloud-platform

kubectl create -f kubernetes/jenkins/jenkins.yaml
kubectl create -f kubernetes/jenkins/service_jenkins.yaml
kubectl create -f kubernetes/jenkins/build_agent.yaml
kubectl scale rc/jenkins-builder --replicas=5
kubectl create -f kubernetes/jenkins/ssl_secrets.yaml
kubectl create -f kubernetes/jenkins/proxy.yaml
kubectl create -f kubernetes/jenkins/service_proxy.yaml
