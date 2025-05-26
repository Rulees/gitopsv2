# cd /root/project_gitlab/scripts/ci
# docker build -t arkselen/ci .
# docker tag arkselen/ci arkselen/ci:v3
# docker push arkselen/ci:v3

FROM alpine/ansible:2.18.1

# Обновляем и ставим базовые пакеты
RUN apk update && apk add --no-cache \
    bash \
    git \
    curl \
    jq \
    python3 \
    py3-pip \
    py3-setuptools \
    py3-wheel \
    make \
    coreutils \
    openssh \
    grep \
    sed \
    docker \
    rsync \
    openssl \
    openrc \
    unzip

ARG TF_VERSION=1.11.1
ARG TG_VERSION=0.80.2

# Установка Terraform
RUN curl -o terraform.zip -SLf https://hashicorp-releases.yandexcloud.net/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
        unzip terraform.zip && \
        mv terraform /usr/local/bin/terraform && \
        chmod +x /usr/local/bin/terraform && \
        rm terraform.zip

# Установка Terragrunt
RUN curl -o /usr/local/bin/terragrunt -SLf https://github.com/gruntwork-io/terragrunt/releases/download/v${TG_VERSION}/terragrunt_linux_amd64 && \
    chmod +x /usr/local/bin/terragrunt


# Установка yc CLI (последняя)
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash && \
    mv /root/yandex-cloud/bin/yc /usr/local/bin/yc

# Установка последней версии SOPS
RUN SOPS_LATEST_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep -Po '"tag_name": "v\K[0-9.]+') && \
    curl -s -LO https://github.com/getsops/sops/releases/download/v${SOPS_LATEST_VERSION}/sops-v${SOPS_LATEST_VERSION}.linux.amd64 && \
    mv sops-v${SOPS_LATEST_VERSION}.linux.amd64 /usr/local/bin/sops && \
    chmod +x /usr/local/bin/sops

# Проверка установок
RUN terragrunt -v && \
    sops -v && \
    yc --version && \
    ansible --version && \
    docker --version && \
    rsync --version
