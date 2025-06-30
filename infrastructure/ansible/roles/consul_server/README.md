1) curl http://localhost:8500/v1/catalog/services
    {"consul":[],"fastapi_instance_group":["env=dev","app=autoscale","service=fastapi_instance_group"]}fhmrtnt75p81o3o0j84n:/#

2) curl http://localhost:8500/v1/catalog/service/fastapi_instance_group

getent hosts service_color.service.consul
