# Aggregate answers from several services to one


# autoscale
1) IG create vms with label(fastapi) 
    > cloud_function_deploy_to_vms_with_labels with roles: fastapi + consul_agent(register every vm as service fastapi)
    > consul_nginx_configure_role creates upstream(with internal addresses of service' vm's) ??? Can we just use dns-name instead of internal adrresses or it is useful?
    > consul_nginx_configure_role creates /location for service

# Aggregated answer by API-Gateway to nginx_upstreams_locations
2) #1 IG create vms with label(service_name)
   #2 IG create vms with label(service_object)
   #2 IG create vms with label(service_color)
    > #1 cloud_function_deploy_to_vms_with_label(service_name)   with roles: fastapi + consul_agent(register every vm as service_name)
    > #2 cloud_function_deploy_to_vms_with_label(service_object) with roles: fastapi + consul_agent(register every vm as service_object)
    > #3 cloud_function_deploy_to_vms_with_label(service_color)  with roles: fastapi + consul_agent(register every vm as service_color)
        > consul_nginx_configure_role  creates upstreams for every service(with internal addresses of service' vm's)
        > consul_nginx_configure_role  creates /location for every service to it's upstream
            > API-Gateway aggregate services by nginx_per_service_location to nginx_per_service_upstream



# Aggregated answer by API-Gateway to exposed internal domain with Consul-per-service
3) #1 IG create vms with label(service_name)
   #2 IG create vms with label(service_object)
   #2 IG create vms with label(service_color)
    > #1 cloud_function_deploy_to_vms_with_label(service_name)   with roles: fastapi + consul_agent(register every vm as service_name)
    > #2 cloud_function_deploy_to_vms_with_label(service_object) with roles: fastapi + consul_agent(register every vm as service_object)
    > #3 cloud_function_deploy_to_vms_with_label(service_color)  with roles: fastapi + consul_agent(register every vm as service_color)
        > consul_nginx_configure_role  creates upstreams for every service(with internal addresses of service' vm's)
        > consul_nginx_configure_role  creates /location for every service to it's upstream
            > API-Gateway aggregate services by consul-exposed-internal-domain-per-service




# Aggregated answer by API-Gateway to exposed internal domain with LoadBalancer-per-service(LB is expensive, unlike consul)
4) 