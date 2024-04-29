FROM ubuntu:jammy-20240416@sha256:6d7b5d3317a71adb5e175640150e44b8b9a9401a7dd394f44840626aff9fa94d

ARG VERSION_JQ=1.7.1
ARG VERSION_KUBECONFORM=0.6.4
ARG VERSION_KUSTOMIZE=5.4.1
ARG VERSION_TRIVY=0.50.1
ARG VERSION_YQ=4.43.1

# install essential tools
RUN apt update && apt install -y \
    apt-transport-https \
    curl \
    git \
    gnupg2 \
    lsb-release \
    sudo

# install kustomize
RUN sudo curl -sSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${VERSION_KUSTOMIZE}/kustomize_v${VERSION_KUSTOMIZE}_linux_amd64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin

# install kubeconform
RUN sudo curl -sSL https://github.com/yannh/kubeconform/releases/download/v${VERSION_KUBECONFORM}/kubeconform-linux-amd64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin

# install trivy
RUN sudo curl -sSL https://github.com/aquasecurity/trivy/releases/download/v${VERSION_TRIVY}/trivy_${VERSION_TRIVY}_Linux-64bit.tar.gz \
    | sudo tar zxf - -C /usr/local/bin

# install jq
RUN sudo curl -sSL -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-${VERSION_JQ}/jq-linux-amd64 \
    && sudo chmod +x /usr/local/bin/jq

# install yq
RUN sudo curl -sSL https://github.com/mikefarah/yq/releases/download/v${VERSION_YQ}/yq_linux_amd64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin && sudo mv /usr/local/bin/yq_linux_amd64 /usr/local/bin/yq

# install krmc
COPY ./krmc.sh /usr/local/bin/
RUN sudo ln -s /usr/local/bin/krmc.sh /usr/local/bin/krmc

# set timezone
ENV TZ="Europe/Berlin"
