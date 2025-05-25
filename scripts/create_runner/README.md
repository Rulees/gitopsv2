1) ssh -l melnikov 89.169.129.240


2) 
# docker install
sudo apt update
sudo apt install curl software-properties-common ca-certificates apt-transport-https -y
wget -O- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable"| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y;
sudo reboot         > reboot computer all
sudo usermod -aG docker $USER
sudo systemctl status docker;
docker --version;

wget https://downloads.nestybox.com/sysbox/releases/v0.6.4/sysbox-ce_0.6.4-0.linux_amd64.deb

sudo apt-get install jq -y
# sudo apt-get install ./sysbox-ce_0.6.4-0.linux_amd64.deb
sudo dpkg -i sysbox-ce_0.6.4-0.linux_amd64.deb

# nano /etc/docker/daemon.json  
{
    "default-runtime": "sysbox-runc",
    "runtimes": {
        "sysbox-runc": {
            "path": "/usr/bin/sysbox-runc"
        }
    },
    "bip": "172.20.0.1/16",
    "default-address-pools": [
        {
            "base": "172.25.0.0/16",
            "size": 24
        }
    ]
}

sudo systemctl restart docker
docker system info | grep -i runtime


3) create runner with untagged > copy token


4) 
docker run --rm \
          -v /root/config:/etc/gitlab-runner  \
          gitlab/gitlab-runner register        \
                                                \
          --non-interactive                      \
          --url "https://gitlab.com/"             \
          --registration-token "glrt-sjMSlsWIihpt3MHoTvYSEm86MQpwOjE1a2Mwegp0OjMKdTpldG45ZRg.01.1j12s7w9x" \
          --executor "docker"                       \
          --docker-image "docker:19.03.12"           \
          --description "runner"                      \
                                                       \
          --locked

5) 
# nano /root/config/config.toml

concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "runner"
  url = "https://gitlab.com/"
  token = "glrt-sjMSlsWIihpt3MHoTvYSEm86MQpwOjE1a2Mwegp0OjMKdTpldG45ZRg.01.1j12s7w9x"
  executor = "docker"

  [runners.docker]
    protected = false
    run_untagged = true
    tls_verify = false
    image = "docker:19.03.12"
    privileged = false
    disable_cache = false
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock",
      "inner-docker-cache:/var/lib/docker",
      "/cache:/cache"]


6) 
docker run --runtime=sysbox-runc -d --name runner --restart always \
        -v /root/config:/etc/gitlab-runner   \
        -v inner-docker-cache:/var/lib/docker \
        -v /cache:/cache                       \
        nestybox/gitlab-runner-docker