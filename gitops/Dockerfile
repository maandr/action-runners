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

ENV KUSTOMIZE_VERSION=5.0.1
ENV KUBECONFORM_VERSION=0.6.1
ENV TRIVY_VERSION=0.39.0

# install kustomize
RUN sudo curl -sSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" > /tmp/install_kustomize.sh \
  && sudo bash /tmp/install_kustomize.sh $KUSTOMIZE_VERSION /usr/local/bin \
  && sudo rm /tmp/install_kustomize.sh

# install kubeconform
RUN sudo curl -sSL https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin

# install trivy
RUN sudo curl -sSL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-ARM64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin
