FROM ghcr.io/actions/actions-runner:latest

USER root

ARG TARGETARCH
ARG TERRAFORM_VERSION=1.13.3
ARG AWS_CLI_VERSION=2.34.63

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) AWS_ARCH=x86_64 ;; \
      arm64) AWS_ARCH=aarch64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    mkdir -p /tmp/runner-tools; \
    cd /tmp/runner-tools; \
    curl -fsSLo terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
    curl -fsSLo terraform_SHA256SUMS \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"; \
    grep " terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip$" terraform_SHA256SUMS \
      | sed "s/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip/terraform.zip/" \
      | sha256sum -c -; \
    unzip terraform.zip -d /usr/local/bin; \
    curl -fsSLo awscliv2.zip \
      "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip"; \
    unzip -q awscliv2.zip; \
    ./aws/install; \
    terraform version; \
    aws --version; \
    rm -rf /tmp/runner-tools

USER runner

WORKDIR /home/runner