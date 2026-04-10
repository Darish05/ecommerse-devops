FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    ansible \
    unzip \
    docker.io \
  && rm -rf /var/lib/apt/lists/*

ARG TERRAFORM_VERSION=1.9.8
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip \
  && unzip /tmp/terraform.zip -d /usr/local/bin \
  && rm -f /tmp/terraform.zip

ARG KUBECTL_VERSION=v1.30.3
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

RUN jenkins-plugin-cli --plugins \
  workflow-aggregator \
  git \
  ansicolor \
  timestamper

USER jenkins
