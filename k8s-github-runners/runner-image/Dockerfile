FROM ubuntu:24.04

ARG TARGETARCH
ARG RUNNER_VERSION=2.338.0
ARG DOCKER_VERSION=29.8.2
ARG BUILDX_VERSION=0.37.2
ARG AWS_CLI_VERSION=2.34.63
ARG TERRAFORM_VERSION=1.13.3

ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq unzip \
    && groupadd --gid 123 docker \
    && useradd --create-home --uid 1001 --shell /bin/bash runner \
    && usermod -aG docker runner \
    && mkdir -p /opt/hostedtoolcache \
    && chown runner:docker /opt/hostedtoolcache \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/runner

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) \
        RUNNER_ARCH=x64; \
        RUNNER_SHA256=af4b794c1bc41d73d40535e3fe092a39f9679cd8d965954c2aca25a05ca41d32 ;; \
      arm64) \
        RUNNER_ARCH=arm64; \
        RUNNER_SHA256=628b4a7258487b80c1d3c221095a7ded349f5ae0175fd3dfab708d07428f041b ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
      -o /tmp/runner.tar.gz; \
    echo "${RUNNER_SHA256}  /tmp/runner.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/runner.tar.gz; \
    ./bin/installdependencies.sh; \
    rm /tmp/runner.tar.gz; \
    rm -rf /var/lib/apt/lists/*; \
    chown -R runner:docker /home/runner

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) DOWNLOAD_ARCH=x86_64 ;; \
      arm64) DOWNLOAD_ARCH=aarch64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL \
      "https://download.docker.com/linux/static/stable/${DOWNLOAD_ARCH}/docker-${DOCKER_VERSION}.tgz" \
      -o /tmp/docker.tgz; \
    tar -xzf /tmp/docker.tgz -C /tmp; \
    install -m 755 /tmp/docker/docker /usr/local/bin/docker; \
    mkdir -p /usr/local/lib/docker/cli-plugins; \
    curl -fsSL \
      "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${TARGETARCH}" \
      -o /usr/local/lib/docker/cli-plugins/docker-buildx; \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx; \
    curl -fsSL \
      "https://awscli.amazonaws.com/awscli-exe-linux-${DOWNLOAD_ARCH}-${AWS_CLI_VERSION}.zip" \
      -o /tmp/awscliv2.zip; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/docker /tmp/docker.tgz /tmp/aws /tmp/awscliv2.zip

RUN set -eux; \
    mkdir -p /tmp/terraform; \
    cd /tmp/terraform; \
    curl -fsSLO \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
    curl -fsSLO \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"; \
    grep " terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip$" \
      "terraform_${TERRAFORM_VERSION}_SHA256SUMS" | sha256sum -c -; \
    unzip "terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
      -d /usr/local/bin; \
    rm -rf /tmp/terraform

USER runner

RUN ./bin/Runner.Listener --version \
    && docker --version \
    && docker buildx version \
    && aws --version \
    && terraform version

CMD ["/home/runner/run.sh"]