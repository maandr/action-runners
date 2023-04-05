FROM ubuntu:latest

# install essential tools
RUN apt update && apt install -y curl sudo gnupg2 wget apt-transport-https lsb-release

ARG BUILDX_VERSION=v0.10.4
ARG NODE_VERSION=18

# install buildx
RUN sudo mkdir -p "${HOME}/.docker/cli-plugins" \
  && sudo curl -SsL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" -o "${HOME}/.docker/cli-plugins/docker-buildx" \
  && sudo chmod +x "${HOME}/.docker/cli-plugins/docker-buildx"

# Install nodejs
RUN sudo curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash - \
    && sudo apt-get update -y \
    && sudo apt-get install -y nodejs

# install trivy
RUN sudo wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null \
  && sudo echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list \
  && sudo apt-get update -y \
  && sudo apt-get install trivy

# set timezone
ENV TZ="Europe/Berlin"
