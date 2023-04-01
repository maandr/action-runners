FROM ubuntu:latest

# install essential tools
RUN apt update && apt install -y curl sudo gnupg2

# install kubectl
RUN sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo apt-key add - \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" \
    | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
    && sudo apt-get update -y \
	  && sudo apt-get install -y kubectl

# install kustomize
RUN sudo curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" \
    | bash

# install kubeconform
RUN sudo curl -sSL https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin
