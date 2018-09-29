#!/bin/bash -e
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

child=0
sig_handler() {
    sig_send=$1
    code=$2
    if [ $child -ne 0 ]; then
        kill -$sig_send $child
        wait $child
    fi
    exit $code
}
trap 'sig_handler HUP 129' HUP
trap 'sig_handler TERM 130' INT
trap 'sig_handler TERM 131' QUIT
trap 'sig_handler TERM 143' TERM

mount --make-shared /

echo > /var/lib/localkube/localkube.err
tail -F /var/log/docker.log /var/log/minikube-start.log /var/lib/localkube/localkube.err &
child=$!

export CNI_BRIDGE_NETWORK_OFFSET="0.0.1.0"

dockerd \
  --host=unix:///var/run/docker.sock \
  --host=tcp://0.0.0.0:2375 \
  &> /var/log/docker.log 2>&1 < /dev/null &


minikube start --vm-driver=none \
 --extra-config=apiserver.Admission.PluginNames=Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota \
 "$@" \
 &> /var/log/minikube-start.log 2>&1 < /dev/null

kubectl config view --merge=true --flatten=true > /kubeconfig

touch /minikube_startup_complete
echo Kubeconfig is ready

# Put the tail of logs in the foreground to keep the container running
wait $child
