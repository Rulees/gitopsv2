# cd /root/project_gitlab/scripts/docker/ci
# docker build -t arkselen/consul-template .
# docker tag arkselen/consul-template arkselen/consul-template:0.40.0
# docker push arkselen/consul-template:0.40.0

FROM hashicorp/consul-template:0.40.0

USER root

# docker cli для перезагрузки nginx внутри другого контейнера
RUN apk add --no-cache docker-cli bash