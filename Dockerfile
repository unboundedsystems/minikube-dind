# Portions Copyright 2016 The Kubernetes Authors All rights reserved.
# Portions Copyright 2018 AspenMesh
# Portions Copyright 2018 Unbounded Systems, LLC
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
#
# Based on:
# https://github.com/kubernetes/minikube/tree/master/deploy/docker/localkube-dind


FROM debian:jessie

# Install minikube dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
  DEBIAN_FRONTEND=noninteractive apt-get -yy -q --no-install-recommends install \
  iptables \
  ebtables \
  ethtool \
  ca-certificates \
  conntrack \
  socat \
  git \
  nfs-common \
  glusterfs-client \
  cifs-utils \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common \
  bridge-utils \
  ipcalc \
  aufs-tools \
  sudo \
  && DEBIAN_FRONTEND=noninteractive apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install docker
RUN \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  apt-key export "9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88" | gpg - && \
  echo "deb [arch=amd64] https://download.docker.com/linux/debian jessie stable" >> \
    /etc/apt/sources.list.d/docker.list && \
  DEBIAN_FRONTEND=noninteractive apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -yy -q --no-install-recommends install \
    docker-ce \
  && DEBIAN_FRONTEND=noninteractive apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /var/lib/docker
EXPOSE 2375
EXPOSE 8443

ENV MINIKUBE_VERSION=v0.25.0 \
    KUBECTL_VERSION=v1.9.1 \
    MINIKUBE_WANTUPDATENOTIFICATION=false \
    MINIKUBE_WANTREPORTERRORPROMPT=false \
    CHANGE_MINIKUBE_NONE_USER=true

# minikube --vm-driver=none checks systemctl before starting.  Instead of
# setting up a real systemd environment, install this shim to tell minikube
# what it wants to know: localkube isn't started yet.
COPY fake-systemctl.sh /usr/local/bin/systemctl
COPY start.sh /start.sh

# Install minikube and kubectl
ADD https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64 /usr/local/bin/minikube
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl

ADD https://storage.googleapis.com/minikube/k8sReleases/v1.8.0/localkube-linux-amd64 /usr/local/bin/localkube

RUN chmod a+rx /usr/local/bin/minikube && \
    chmod a+rx /usr/local/bin/systemctl && \
    chmod a+rx /usr/local/bin/kubectl && \
    chmod a+rx /start.sh && \
    chmod a+rx /usr/local/bin/localkube && \
    mkdir -p /root/.minikube/cache/localkube && \
    cp /usr/local/bin/localkube /root/.minikube/cache/localkube/localkube-v1.8.0 && \
    echo 546bd1980d0ea7424a21fc7ff3d7a8afd7809cefd362546d40f19a40d805f553 > /root/.minikube/cache/localkube/localkube-v1.8.0.sha256

# If nothing else specified, start up docker and kubernetes.
CMD [ "/bin/bash", "-c", "/start.sh" ]
