# cd /root/project_gitlab/scripts/ci
# docker build -t arkselen/ci .
# docker tag arkselen/ci:v2
# docker push arkselen/ci:v2

FROM alpine/terragrunt:tf1.12.1

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
    openssl

RUN pip install --break-system-packages --upgrade ansible

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
    docker --version
    rsync --version
