# Configure Terragrunt to automatically store tfstate files in an S3 bucket
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    
  terraform {
    backend "s3" {
      region         = "ru-central1"
      bucket         = "project-dildakot--yc-backend--dmvlelmn"                                                          # change
      key            = "${path_relative_to_include()}/terraform.tfstate"

      dynamodb_table = "project-dildakot--yc-backend--state-lock-table"                                                  # change

      endpoints = {
        s3       = "https://storage.yandexcloud.net",
        dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g6lfsqbtpq384k0vrj/etn4eoef8obmfvkvrhqs"      # change
      }

      skip_credentials_validation = true
      skip_region_validation      = true
      skip_requesting_account_id  = true
      skip_s3_checksum            = true
    }
  }
  EOF
}


# Generate an YC provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

  # PROVIDER.TF
  terraform {
    required_providers {
      yandex = {
        source  = "yandex-cloud/yandex"
        version = "= 0.141.0"
      }
      aws = {
        source  = "hashicorp/aws"
        version = "= 5.44.0"
      }
      random = {
        source = "hashicorp/random"
        version = "= 3.6.3"
      }
      time = {
        source = "hashicorp/time"
        version = "= 0.12.1"
      }
      local = {
        source = "hashicorp/local"
        version = "= 2.5.1"
      }
      archive = {
        source = "hashicorp/archive"
        version = "2.7.1"
      }
      null = {
        source = "hashicorp/null"
        version = "3.2.4"
      }
      atlas = {
        source  = "ariga/atlas"
        version = "0.9.8"
      }
    }
    required_version = ">= 1.9.4"
  }

  provider "yandex" {
    folder_id = var.folder_id
    zone      = var.region
  }


  # VARIABLES
  variable "region" {
    description = "Example: ru-central1"
    type        = string
  }

  variable "folder_id" {
    description = "ID of folder"
    type        = string
  }
  EOF
}

# Generate lock file for different platforms to reduce cicd time
generate "lock" {
  path      = ".terraform.lock.hcl"
  if_exists = "overwrite"
  contents  = <<EOF
  # This file is maintained automatically by "terraform init".
  # Manual edits may be lost in future updates.

  provider "registry.terraform.io/hashicorp/local" {
    version     = "2.5.1"
    constraints = "2.5.1"
    hashes = [
      "h1:8oTPe2VUL6E2d3OcrvqyjI4Nn/Y/UEQN26WLk5O/B0g=",
      "h1:fm2EuMlsdPTuv2tKwx3PMJzWJUh7aMtU9Eky7t4fMys=",
      "zh:0af29ce2b7b5712319bf6424cb58d13b852bf9a777011a545fac99c7fdcdf561",
      "zh:126063ea0d79dad1f68fa4e4d556793c0108ce278034f101d1dbbb2463924561",
      "zh:196bfb49086f22fd4db46033e01655b0e5e036a5582d250412cc690fa7995de5",
      "zh:37c92ec084d059d37d6cffdb683ccf68e3a5f8d2eb69dd73c8e43ad003ef8d24",
      "zh:4269f01a98513651ad66763c16b268f4c2da76cc892ccfd54b401fff6cc11667",
      "zh:51904350b9c728f963eef0c28f1d43e73d010333133eb7f30999a8fb6a0cc3d8",
      "zh:73a66611359b83d0c3fcba2984610273f7954002febb8a57242bbb86d967b635",
      "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
      "zh:7ae387993a92bcc379063229b3cce8af7eaf082dd9306598fcd42352994d2de0",
      "zh:9e0f365f807b088646db6e4a8d4b188129d9ebdbcf2568c8ab33bddd1b82c867",
      "zh:b5263acbd8ae51c9cbffa79743fbcadcb7908057c87eb22fd9048268056efbc4",
      "zh:dfcd88ac5f13c0d04e24be00b686d069b4879cc4add1b7b1a8ae545783d97520",

    ]
  }




  provider "registry.terraform.io/hashicorp/aws" {
    version     = "5.44.0"
    constraints = "5.44.0"
    hashes = [
      "h1:QqMTKuyylmJ633mwNheXdFupfd5sozqCUTTSj89pnm8=",
      "h1:vFYi1r4ge/VvhMtN2duljKR+0YlEiWOx+PN9pfynW9k=",
      "zh:1224a42bb04574785549b89815d98bda11f6e9992352fc6c36c5622f3aea91c0",
      "zh:2a8d1095a2f1ab097f516d9e7e0d289337849eebb3fcc34f075070c65063f4fa",
      "zh:46cce11150eb4934196d9bff693b72d0494c85917ceb3c2914d5ff4a785af861",
      "zh:4a7c15d585ee747d17f4b3904851cd95cfbb920fa197aed3df78e8d7ef9609b6",
      "zh:508f1a85a0b0f93bf26341207d809bd55b60c8fdeede40097d91f30111fc6f5d",
      "zh:52f968ffc21240213110378d0ffb298cbd23e9157a6d01dfac5a4360492d69c2",
      "zh:5e9846b48ef03eb59541049e81b15cae8bc7696a3779ae4a5412fdce60bb24e0",
      "zh:850398aecaf7dc0231fc320fdd6dffe41836e07a54c8c7b40eb28e7525d3c0a9",
      "zh:8f87eeb05bdd1b873b6cfb3898dfad6402ac180dfa3c8f9754df8f85dcf92ca6",
      "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
      "zh:c726b87cd6ed111536f875dccedecff21abc802a4087264515ffab113cac36dc",
      "zh:d57ea706d2f98b93c7b05b0c6bc3420de8e8cf2d0b6703085dc15ed239b2cc49",
      "zh:d5d1a21246e68c2a7a04c5619eb0ad5a81644f644c432cb690537b816a156de2",
      "zh:e869904cac41114b7e4ee66bcd2ce4585ed15ca842040a60cb47119f69472c91",
      "zh:f1a09f2f3ea72cbe795b865cf31ad9b1866a536a8050cf0bb93d3fa51069582e",
    ]
  }

  provider "registry.terraform.io/hashicorp/random" {
    version     = "3.6.3"
    constraints = "3.6.3"
    hashes = [
      "h1:Fnaec9vA8sZ8BXVlN3Xn9Jz3zghSETIKg7ch8oXhxno=",
      "h1:In4XBRMdhY89yUoTUyar3wDF28RJlDpQzdjahp59FAk=",
      "zh:04ceb65210251339f07cd4611885d242cd4d0c7306e86dda9785396807c00451",
      "zh:448f56199f3e99ff75d5c0afacae867ee795e4dfda6cb5f8e3b2a72ec3583dd8",
      "zh:4b4c11ccfba7319e901df2dac836b1ae8f12185e37249e8d870ee10bb87a13fe",
      "zh:4fa45c44c0de582c2edb8a2e054f55124520c16a39b2dfc0355929063b6395b1",
      "zh:588508280501a06259e023b0695f6a18149a3816d259655c424d068982cbdd36",
      "zh:737c4d99a87d2a4d1ac0a54a73d2cb62974ccb2edbd234f333abd079a32ebc9e",
      "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
      "zh:a357ab512e5ebc6d1fda1382503109766e21bbfdfaa9ccda43d313c122069b30",
      "zh:c51bfb15e7d52cc1a2eaec2a903ac2aff15d162c172b1b4c17675190e8147615",
      "zh:e0951ee6fa9df90433728b96381fb867e3db98f66f735e0c3e24f8f16903f0ad",
      "zh:e3cdcb4e73740621dabd82ee6a37d6cfce7fee2a03d8074df65086760f5cf556",
      "zh:eff58323099f1bd9a0bec7cb04f717e7f1b2774c7d612bf7581797e1622613a0",

    ]
  }

  provider "registry.terraform.io/hashicorp/time" {
    version     = "0.12.1"
    constraints = "0.12.1"
    hashes = [
      "h1:6BhxSYBJdBBKyuqatOGkuPKVenfx6UmLdiI13Pb3his=",
      "h1:ny87bLSd1q3AcQNBXmKhUHRBErwuPEX/nCa05C7tyF0=",
      "zh:090023137df8effe8804e81c65f636dadf8f9d35b79c3afff282d39367ba44b2",
      "zh:26f1e458358ba55f6558613f1427dcfa6ae2be5119b722d0b3adb27cd001efea",
      "zh:272ccc73a03384b72b964918c7afeb22c2e6be22460d92b150aaf28f29a7d511",
      "zh:438b8c74f5ed62fe921bd1078abe628a6675e44912933100ea4fa26863e340e9",
      "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
      "zh:85c8bd8eefc4afc33445de2ee7fbf33a7807bc34eb3734b8eefa4e98e4cddf38",
      "zh:98bbe309c9ff5b2352de6a047e0ec6c7e3764b4ed3dfd370839c4be2fbfff869",
      "zh:9c7bf8c56da1b124e0e2f3210a1915e778bab2be924481af684695b52672891e",
      "zh:d2200f7f6ab8ecb8373cda796b864ad4867f5c255cff9d3b032f666e4c78f625",
      "zh:d8c7926feaddfdc08d5ebb41b03445166df8c125417b28d64712dccd9feef136",
      "zh:e2412a192fc340c61b373d6c20c9d805d7d3dee6c720c34db23c2a8ff0abd71b",
      "zh:e6ac6bba391afe728a099df344dbd6481425b06d61697522017b8f7a59957d44",

    ]
  }

  # provider "registry.terraform.io/yandex-cloud/yandex" {
  #   version     = "0.127.0"
  #   constraints = "0.127.0"
  #   hashes = [
  #     "h1:+JXzURzuTrJAGlaoLf/l6iTonqgH2dXxP3PMpy+z2Gk=",
  #     "h1:VvMUZzXA2T+Fqwpb2X/VdHNW0cKa/5Q38AStHaLBEWI=",
  #     "h1:hlZwPqf/ezogE55ikhMB3rqbC5EDbpGIjYi1PgOJqqo=",
  #     "h1:isxtbO5Ts+O9D4gJNUuOKWYn5dtg48Ynr81hwiLhotQ=",
  #     "h1:mq8NXnXXPYMSQWHV7V7fCrQFFg6CG/urTlzt+NOwW7Q=",
  #     "h1:tms24VWADoryHdkGdH5A76fWG2k+9CrE9Je9yZMXUoI=",
  #     "zh:0791d3d9373d05b31501264ca0f64b6f60055ca39193fd165ad43b7c87c5c8d1",
  #     "zh:18465fc57492b8f50a126f6189198d79f08445b252242987d9b40be58ed1297a",
  #     "zh:359c66db78163320232db69ef94b5327bc1adab661edcde93dfd370e1ad3f1c4",
  #     "zh:3f990a840999e46bb3ee9bacc5b91e0e1c681ffc00b46fd68faebb6ebe75239e",
  #     "zh:7696d4a82eb1e68e67246e25f787178deed709604140eed27a3b8d03cca74b97",
  #     "zh:8cab8ea3f664991f01b17016b6cd815d27d740c7d17904305119c1a2048b4776",
  #     "zh:8d8099a5a1038b4cb15f140d5eabfc5cc2ac9fee0a183c572ecb4965c9fbdf05",
  #     "zh:a2d43a331fc97ffe0735c411ddb86b7a80649d2eaba9b3bf557d8588d101fc28",
  #     "zh:c1faa0b8df609c4f1600d1c90b4c99e7ccf594859a7de91a0855a0cf4dbead46",
  #     "zh:cb4bb98befea9a2bd684097a9f957748a0e9b77089d303e95389ec2f4817777c",
  #     "zh:e7b4720add3457ce54f6ba5146d5e49e1481e4922859534c367ad29082ee08df",
  #     "zh:f0c80d5e13ba98fb9f89ba5967d07ab7718a879b9f1734bd213c23a07574c6a4",
  #     "zh:f2000a129c8bfd742c221c8c693d30992163276701679e7c33aad8640928a6c3",
  #   ]
  # }

  provider "registry.terraform.io/yandex-cloud/yandex" {
    version     = "0.141.0"
    constraints = "0.141.0"
    hashes = [
      "h1:YnTOy3shxgWQdIea/KpoEka1P9YHUMFTm7vm1EobDUo=",
      "h1:bQY/gnNdMio2eeZrinYGsSkOWtfvngnvsCkO6/4HUuc=",
      "zh:14c0405a53a4b2ccc3700c3e1ddeebdd4b29d90c82ea0210736d485abc5f49f5",
      "zh:24d244a1c5a55efbb52012748dbf022276205259dfc3d2c3c4690bd55c04b663",
      "zh:2e7b7547488bcbb9219793a6e1fe74c0a7eae4ffe94a2a6b17dd43a7316e5262",
      "zh:2ec33f360bc2cf2a37f1627b616e69130d629ef3f9d0736ca03c303fc641a132",
      "zh:44ec0938b750b539b580da1be799905209a6ef9ca94edd5978bba4865a335ad5",
      "zh:4e851bca70e62e306a3ee2ddc2b747b15832565d38c700a6611c892c3ab10af7",
      "zh:5ab4c641335a886e2e8dcc6776d9215467d7b385dfcc69bb1fe8306d8c8d31b9",
      "zh:a3adbaa8c85545dea899e9f9ca6de7effa59c10cd823d97ea2e1d3dd8341ea6d",
      "zh:ace552b8b079eb5133af7e168412f1974eebb582f2f4edf1b4998502887b4092",
      "zh:b70f953d0aa12146fd599c7e53e263f10470ecb1b339804cc182c4aa923d544f",
      "zh:cc2992ca75ef363c547c7b6e54eb2df6cd35d356ec2b6143155d4893305722e6",
      "zh:d89c1669793a9abfb844a54ffdf47d0e58bb237017ccc8500be02db3431f62ff",
      "zh:f7d5bcbffb64f8d7c6f56b8e7ccfbbda190d04fc0d1207ed8e542ca38077bfb8",

    ]
  }
  provider "registry.terraform.io/hashicorp/archive" {
    version     = "2.7.1"
    constraints = "2.7.1"
    hashes = [
      "h1:62VrkalDPMKB9zerCBS4iKTbvxejwnAWn/XXYZZQWD4=",
      "h1:MwZ8uhTOmj3W8wiMeitCnzuf+897qka4/NBIAWFrm+k=",
      "zh:19881bb356a4a656a865f48aee70c0b8a03c35951b7799b6113883f67f196e8e",
      "zh:2fcfbf6318dd514863268b09bbe19bfc958339c636bcbcc3664b45f2b8bf5cc6",
      "zh:3323ab9a504ce0a115c28e64d0739369fe85151291a2ce480d51ccbb0c381ac5",
      "zh:362674746fb3da3ab9bd4e70c75a3cdd9801a6cf258991102e2c46669cf68e19",
      "zh:7140a46d748fdd12212161445c46bbbf30a3f4586c6ac97dd497f0c2565fe949",
      "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
      "zh:875e6ce78b10f73b1efc849bfcc7af3a28c83a52f878f503bb22776f71d79521",
      "zh:b872c6ed24e38428d817ebfb214da69ea7eefc2c38e5a774db2ccd58e54d3a22",
      "zh:cd6a44f731c1633ae5d37662af86e7b01ae4c96eb8b04144255824c3f350392d",
      "zh:e0600f5e8da12710b0c52d6df0ba147a5486427c1a2cc78f31eea37a47ee1b07",
      "zh:f21b2e2563bbb1e44e73557bcd6cdbc1ceb369d471049c40eb56cb84b6317a60",
      "zh:f752829eba1cc04a479cf7ae7271526b402e206d5bcf1fcce9f535de5ff9e4e6",
    ]
  }

  provider "registry.terraform.io/hashicorp/null" {
    version     = "3.2.4"
    constraints = "3.2.4"
    hashes = [
      "h1:hkf5w5B6q8e2A42ND2CjAvgvSN3puAosDmOJb3zCVQM=",
      "h1:wTNrZnwQdOOT/TW9pa+7GgJeFK2OvTvDmx78VmUmZXM=",
      "zh:59f6b52ab4ff35739647f9509ee6d93d7c032985d9f8c6237d1f8a59471bbbe2",
      "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
      "zh:795c897119ff082133150121d39ff26cb5f89a730a2c8c26f3a9c1abf81a9c43",
      "zh:7b9c7b16f118fbc2b05a983817b8ce2f86df125857966ad356353baf4bff5c0a",
      "zh:85e33ab43e0e1726e5f97a874b8e24820b6565ff8076523cc2922ba671492991",
      "zh:9d32ac3619cfc93eb3c4f423492a8e0f79db05fec58e449dee9b2d5873d5f69f",
      "zh:9e15c3c9dd8e0d1e3731841d44c34571b6c97f5b95e8296a45318b94e5287a6e",
      "zh:b4c2ab35d1b7696c30b64bf2c0f3a62329107bd1a9121ce70683dec58af19615",
      "zh:c43723e8cc65bcdf5e0c92581dcbbdcbdcf18b8d2037406a5f2033b1e22de442",
      "zh:ceb5495d9c31bfb299d246ab333f08c7fb0d67a4f82681fbf47f2a21c3e11ab5",
      "zh:e171026b3659305c558d9804062762d168f50ba02b88b231d20ec99578a6233f",
      "zh:ed0fe2acdb61330b01841fa790be00ec6beaac91d41f311fb8254f74eb6a711f",

    ]
  }

  provider "registry.terraform.io/ariga/atlas" {
    version     = "0.9.8"
    constraints = "0.9.8"
    hashes = [
      "h1:Ra44rn/2eb3kpMriqMVmB3RZl1uJ1/B6N5Rt7s6Gg4U=",
      "h1:u1bsx6PE27yHeRClqElhHetgzLLm95aTRLcyMVQCmc4=",
      "zh:03477f46e1c6d4d393f766c49106520fa128893796ef665edafa21f5306be78a",
      "zh:0e5c9b0383580243ae96e06addb3965220559997f2bf1f4612cacddd6c8cc902",
      "zh:6c24eccdf47e1ea73c9a25ffbdbcd08e0a4cb45cad321ce6345726c2bd3d0327",
      "zh:81cdaf589f22b0c99b2c83261c7867735a99fe4fd0fa38be4c901c4170daf3f7",
      "zh:cbbdea7f0a81fb3769cd708ec51c526401740451b482f7cd97b3bdcea4b9883c",
      "zh:f809ab383cca0a5f83072981c64208cbd7fa67e986a86ee02dd2c82333221e32",
    ]
  }
  EOF
}


locals {
  work_dir       = get_env("WORK_DIR")
  region         = "ru-central1"
  folder_id      = "b1g1s1l8qr1m59f3orlt"
  project_prefix = "project"
  env_vars       = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract app/service/subservice automatically for assigning labels
  parts          = split("/", path_relative_to_include())
  i              = 2
  app            = try(local.parts[local.i+1], "")
  service        = try(local.parts[local.i+2], "")
  subservice     = try(local.parts[local.i+3], "")
}

inputs = {
  work_dir       = local.work_dir
  region         = local.region
  folder_id      = local.folder_id
  project_prefix = local.project_prefix
}

