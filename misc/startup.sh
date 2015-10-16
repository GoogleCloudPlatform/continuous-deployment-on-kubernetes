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

#!/bin/bash
apt-get upgrade -y
apt-get install -y git

# Configure gcloud
gcloud components update kubectl --quiet
ln -s /usr/local/share/google/google-cloud-sdk/bin/kubectl /usr/local/bin/kubectl

cat <<"EOF" > /etc/profile.d/gtc.sh
if [ ! -f "$HOME/.gtcinit" ]; then
  echo "INITIALIZING INSTANCE FOR GTC LAB"
  gcloud config set compute/zone us-central1-f

  # Make project dir
  if [ ! -d "$HOME/gtc" ]; then
    mkdir -p $HOME/gtc 
  fi

  # Clone jenkins-kube-cd
  if [ ! -d "$HOME/gtc/jenkins-kube-cd" ]; then
    cd $HOME/gtc
    git clone https://github.com/evandbrown/jenkins-kube-cd.git
  fi
  touch $HOME/.gtcinit
fi
EOF
