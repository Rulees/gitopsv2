1. curl http://localhost:8500/v1/catalog/services
   {"consul":[],"fastapi_instance_group":["env=dev","app=autoscale","service=fastapi_instance_group"]}fhmrtnt75p81o3o0j84n:/#

2. curl http://localhost:8500/v1/catalog/service/fastapi_instance_group

getent hosts service_color.service.consul

3. if error 2025-10-30T18:54:43.406Z [WARN] agent: Check is now critical: check=service:monitoring
   check ip: nano /opt/consul/config/monitoring.json
   check port: ss -tulnp
   nano /root/project_gitlab/infrastructure/ansible/roles/consul_agent/defaults

   consul_version: "1.21.1"
   consul_service_name: "{{ service }}"
   consul_service_port: 8500 # change this
   consul_service_tags: ["env={{ env }}", "app={{ app }}", "service={{ service }}"]
   consul_check_http: "http://localhost:{{ consul_service_port }}/v1/agent/self" # change this
   consul_check_interval: "10s"
