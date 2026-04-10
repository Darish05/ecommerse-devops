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

ARG DOCKER_CLI_VERSION=27.1.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" -o /tmp/docker.tgz \
  && tar -xzf /tmp/docker.tgz -C /tmp \
  && install -m 0755 /tmp/docker/docker /usr/local/bin/docker \
  && rm -rf /tmp/docker /tmp/docker.tgz

ARG DOCKER_COMPOSE_VERSION=v2.29.2
RUN curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

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
