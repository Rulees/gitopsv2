# ORDER OF THINGS
1) Ansible new push image with tag 'latest'
2) module serverless trigger: yandex_function_trigger see this and call to yandex_function to use python-sdk-grpc to do redeploy serverless-container. Redeploy require all valuse, not just image, so yandex_function inherit values by outputs from serverless_website and send as json to API.


# How yandex_function deos inherit values?
1) /modules/serverless/outputs.tf
2) /website_serverless/trigger/terragrunt.hcl
3) /modules/serverless_trigger/vars.tf
4) /modules/serverless_trigger/function/main.py
5) /modules/serverless_trigger/main-function.tf

# Important moments
connectivity has not be sended inside /function/main.py