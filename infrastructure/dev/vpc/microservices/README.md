# Aggregate answers from several services to one

##
# Autoscale
##
1)   IG create vms with label(fastapi) 
2)        🏀 cloud_function_deploy_to_vms_with_labels with roles: fastapi + consul_agent(register every vm as service fastapi)
3)             🌟 consul_nginx_configure_role creates upstream(with internal addresses of service' vm's) # consul-dns can be used, then only round-robin and no L7-functions
4)             🌟 consul_nginx_configure_role creates /location for service



##
# 1_Aggregated answer by API-Gateway to nginx_upstreams_locations
##
1)   IG create vms with label(service_name)
     IG create vms with label(service_object)
     ...
2)        🏀 cloud_function_deploy_to_vms_with_label(service_name)   with roles: fastapi + consul_agent(register every vm as service_name)
          🏀 cloud_function_deploy_to_vms_with_label(service_object) with roles: fastapi + consul_agent(register every vm as service_object)
              ...
3)             🌟 consul_nginx_configure_role creates upstreams for every service(with internal addresses of service' vm's)
               🌟 consul_nginx_configure_role creates /location for every service to it's upstream
4)                 ✅ API-Gateway aggregate services by *nginx*_per_service_location to nginx_per_service_upstream



##
# 2_Aggregated answer by API-Gateway to exposed internal domain with Consul_per_service
##
1)   IG create vms with label(service_name)
     IG create vms with label(service_object)
     ...
2)        🏀 cloud_function_deploy_to_vms_with_label(service_name)   with roles: fastapi + consul_agent(register every vm as service_name)
          🏀 cloud_function_deploy_to_vms_with_label(service_object) with roles: fastapi + consul_agent(register every vm as service_object)
              ...
3)                  ✅ API-Gateway aggregate services by *consul*_exposed_internal_domain_per_service



##
# 3_Aggregated answer by API-Gateway to exposed internal domain with LoadBalancer_per_service(LB is expensive, unlike consul)
##