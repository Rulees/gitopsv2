# cd /root/project_gitlab/scripts/docker/autoscale
# docker build -t arkselen/autoscale .
# docker tag arkselen/autoscale arkselen/autoscale:v1
# docker push arkselen/autoscale:v1

# 25.04
FROM ubuntu@sha256:79efa276fdefa2ee3911db29b0608f8c0561c347ec3f4d4139980d43b168d991

# Обновляем и ставим базовые пакеты
RUN apt update && apt install -y --no-install-recommends \
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
    apt install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Добавление root в группу docker
RUN groupadd docker || true && usermod -aG docker root    

# Установка Ansible
RUN pip install --break-system-packages --upgrade ansible

# Установка последней версии SOPS
RUN SOPS_LATEST_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep -Po '"tag_name": "v\K[0-9.]+') && \
    curl -s -LO https://github.com/getsops/sops/releases/download/v${SOPS_LATEST_VERSION}/sops-v${SOPS_LATEST_VERSION}.linux.amd64 && \
    mv sops-v${SOPS_LATEST_VERSION}.linux.amd64 /usr/local/bin/sops && \
    chmod +x /usr/local/bin/sops

# Проверка установок
RUN sops -v && \
    ansible --version && \
    docker --version && \
    rsync --version