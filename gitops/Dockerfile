FROM ubuntu:latest

ARG KUSTOMIZE_VERSION=5.0.1
ARG KUBECONFORM_VERSION=0.6.1

# install essential tools
RUN apt update && apt install -y curl sudo gnupg2 wget apt-transport-https lsb-release

# install kubectl
RUN sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo apt-key add - \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" \
    | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
    && sudo apt-get update -y \
	  && sudo apt-get install -y kubectl

# install kustomize
RUN sudo curl -sSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" > /tmp/install_kustomize.sh \
  && sudo bash /tmp/install_kustomize.sh $KUSTOMIZE_VERSION /usr/local/bin \
  && sudo rm /tmp/install_kustomize.sh

# install kubeconform
RUN sudo curl -sSL https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz \
    | sudo tar zxf - -C /usr/local/bin

# install trivy
RUN sudo wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null \
  && sudo echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list \
  && sudo apt-get update -y \
  && sudo apt-get install trivy

# install jq

# set timezone
ENV TZ="Europe/Berlin"
