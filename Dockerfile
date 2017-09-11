FROM ubuntu:16.04

MAINTAINER Matthew Titmus <matthew.titmus@gmail.com>

ARG AWSCLI_VERSION=1.11.13-1ubuntu1~16.04.0
ARG HELM_VERSION=2.6.1
ARG KOPS_VERSION=1.7.0
ARG KUBECTL_VERSION=1.7.5

# Install AWS CLI
#
RUN apt-get update                                          \
  && apt-get -y --force-yes install --no-install-recommends \
    awscli=${AWSCLI_VERSION}                                \
    curl                                                    \
    dnsutils                                                \
    ssh                                                     \
    vim                                                     \
    wget                                                    \
  && apt-get clean                                          \
  && apt-get autoclean                                      \
  && apt-get autoremove                                     \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install kubectl
#
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Install Kops
#
ADD https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 /usr/local/bin/kops
RUN chmod +x /usr/local/bin/kops

# Install Helm
#
RUN wget -O helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
	&& tar xfz helm.tar.gz \
	&& mv linux-amd64/helm /usr/local/bin/helm \
	&& chmod +x /usr/local/bin/helm \
	&& rm -Rf linux-amd64 \
	&& rm helm.tar.gz

# Create default user "kops"
#
RUN useradd -ms /bin/bash kops
WORKDIR /home/kops

USER kops
