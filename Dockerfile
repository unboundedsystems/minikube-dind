FROM quay.io/aspenmesh/minikube-dind
ADD https://storage.googleapis.com/minikube/k8sReleases/v1.8.0/localkube-linux-amd64 /usr/local/bin/localkube
RUN mkdir -p /root/.minikube/cache/localkube && \
    cp /usr/local/bin/localkube /root/.minikube/cache/localkube/localkube-v1.8.0 && \
    echo 546bd1980d0ea7424a21fc7ff3d7a8afd7809cefd362546d40f19a40d805f553 > /root/.minikube/cache/localkube/localkube-v1.8.0.sha256
