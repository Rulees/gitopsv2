# 2
terraform {
  source = "${get_repo_root()}/modules//sg/"
}


include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}


dependency "network" {
  config_path                             = "../../../../network/"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info", "show"] # Configure mock outputs for commands that are returned when there are no outputs available (e.g the module hasn't been applied yet.)
  mock_outputs = {
    vpc_id     = "network-id-fake"
    subnet_id  = "subnet-id-fake"
  }
}


inputs = {
  env        = include.root.locals.env_vars.locals.env
  zone       = include.root.locals.env_vars.locals.zone
  network_id = dependency.network.outputs.vpc_id
  sg_name    = "svc_db"
  

  security_group_runners = [
    ##
    # MONITORING
    ##
    {
      direction      = "ingress"
      description    = "from external VictoriaMetricsAgent to internal NodeExporter"
      protocol       = "TCP"
      ports          = [9100]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    {
      direction      = "egress"
      description    = "from internal Promtail to external Loki"
      protocol       = "TCP"
      ports          = [3100]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    ##
    # CONSUL
    ##
    {
      direction      = "ingress"
      description    = "Consul"
      protocol       = "TCP"
      ports          = [8300, 8301, 8302, 8500, 8600]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    {
      direction      = "ingress"
      description    = "Consul"
      protocol       = "UDP"
      ports          = [8300, 8301, 8302, 8500, 8600]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    {
      direction      = "egress"
      description    = "Consul"
      protocol       = "TCP"
      ports          = [8300, 8301, 8302, 8500, 8600]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    {
      direction      = "egress"
      description    = "Consul"
      protocol       = "UDP"
      ports          = [8300, 8301, 8302, 8500, 8600]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    ##
    # FASTAPI
    ##
    {
      direction      = "egress"
      description    = "from internal Fastapi to external Postgres"
      protocol       = "TCP"
      ports          = [6432]
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
    {
      direction      = "ingress"
      description    = "from external Nginx/ConsulServer to internal Fastapi"
      protocol       = "TCP"
      ports          = [8000]
      v4_cidr_blocks = ["10.10.0.0/24"]
    },
    ##
    # DEFAULT
    ##
    {
      direction      = "ingress"
      description    = "outgoing SSH"
      protocol       = "TCP"
      ports          = [22]
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
    {
      direction      = "egress"
      description    = "incoming SSH"
      protocol       = "TCP"
      ports          = [22]
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
     {
      direction      = "egress"
      description    = "outgoing HTTP/HTTPS"
      protocol       = "TCP"
      ports          = [80, 443]
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
