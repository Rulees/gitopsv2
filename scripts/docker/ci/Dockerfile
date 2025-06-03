# cd /root/project_gitlab/scripts/ci
# docker build -t arkselen/ci .
# docker tag arkselen/ci arkselen/ci:v3
# docker push arkselen/ci:v3

# 25.04
FROM ubuntu@sha256:79efa276fdefa2ee3911db29b0608f8c0561c347ec3f4d4139980d43b168d991

ARG TF_VERSION=1.11.1
ARG TG_VERSION=0.80.2

# Обновляем и ставим базовые пакеты
RUN apt update && apt install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    bash \
    git \
    curl \
    gnupg \
    jq \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    make \
    coreutils \
    openssh-client \
    grep \
    sed \
    rsync \
    unzip \
    lsb-release \
    software-properties-common \
    openssl \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Установка Docker через официальный репозиторий
RUN curl -fSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt update && \
    apt install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Добавление root в группу docker
RUN groupadd docker || true && usermod -aG docker root    

# Установка Ansible
RUN pip install --break-system-packages --upgrade ansible


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