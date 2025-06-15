import os, time, json, jwt, requests
from yandexcloud import SDK
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2_grpc import InstanceGroupServiceStub
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2 import ListInstanceGroupInstancesRequest
from yandex.cloud.compute.v1.instance_service_pb2_grpc import InstanceServiceStub
from yandex.cloud.compute.v1.instance_service_pb2 import GetInstanceRequest



def handler(event, context):
    try:
        print("🟡 Reading SA key from file...")
        key_path = os.path.join(os.path.dirname(__file__), "sa_key.json")
        with open(key_path, "r") as f:
            sa_key = json.load(f)

        private_key = sa_key["private_key"]
        key_id = sa_key["id"]
        sa_id = sa_key["service_account_id"]

        print(f"🔐 SA ID: {sa_id}, Key ID: {key_id}")

        # Generate JWT for Yandex authentication
        now = int(time.time())
        payload = {
            "aud": "https://iam.api.cloud.yandex.net/iam/v1/tokens",
            "iss": sa_id,
            "iat": now,
            "exp": now + 360
        }

        jwt_token = jwt.encode(payload, private_key, algorithm="PS256", headers={"kid": key_id})
        print("🔑 JWT created")

        iam_url = "https://iam.api.cloud.yandex.net/iam/v1/tokens"
        resp = requests.post(iam_url, json={"jwt": jwt_token})
        if resp.status_code != 200:
            print(f"❌ Failed to get IAM token: {resp.status_code} {resp.text}")
            return
        iam_token = resp.json()["iamToken"]
        print("🟢 IAM token received")

        sdk = SDK(token=None, iam_token=iam_token, jwt=jwt_token)
        group_client = sdk.client(InstanceGroupServiceStub)
        instance_client = sdk.client(InstanceServiceStub)

        instance_group_id = os.environ.get('INSTANCE_GROUP_ID')

        while True:  # Loop to call every 10 seconds
            instances = group_client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances
            non_deployed_instances = []

            for inst in instances:
                info = instance_client.Get(GetInstanceRequest(instance_id=inst.instance_id))
                deploy_status = info.labels.get("deploy_status")

                print(f"Instance: {inst.instance_id}, status: {inst.status}, labels: {info.labels}")

                if inst.status in (16, 17, 19, 21) and deploy_status not in ("true", "in_process", "error"):
                    non_deployed_instances.append(info)

            if non_deployed_instances:
                print("⏳ Wait 10s to check for more instances...")
                time.sleep(10)

                # ВТОРОЙ ПРОХОД: повторная проверка через 10 секунд
                instances = group_client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances
                non_deployed_instances = []             
                for inst in instances:
                    info = instance_client.Get(GetInstanceRequest(instance_id=inst.instance_id))
                    deploy_status = info.labels.get("deploy_status")
                    if inst.status in (16, 17, 19, 21) and deploy_status not in ("true", "in_process", "error"): # 16=awaiting, 17=checking_health
                        non_deployed_instances.append(info)

                # Теперь обновляем labels и деплоим
                if non_deployed_instances:
                    print(f"🔄 Found {len(non_deployed_instances)} not_deployed_instances")
                    trigger_gitlab_pipeline(iam_token, instance_group_id)

                    for inst in non_deployed_instances:
                        labels = dict(inst.labels, deploy_status="in_process")
                        url = f"https://compute.api.cloud.yandex.net/compute/v1/instances/{inst.id}"
                        body = {"updateMask": "labels", "labels": labels}
                        headers = {"Authorization": f"Bearer {iam_token}", "Content-Type": "application/json"}

                        response = requests.patch(url, headers=headers, json=body)
                        if response.status_code in (200, 201):
                            print(f"✅ Instance {inst.id}: in_process")
                        else:
                            print(f"❌ Failed to add tag: {response.status_code} {response.text}")
                        

                    print("✅ Instances processed and tagged.")
                

            print("⏳ Wait 10s, before next check...")
            time.sleep(10)

    except Exception as e:
        print(f"❌ Error: {e}")
        return {
            "statusCode": 500,
            "body": f"❌ Exception: {str(e)}"
        }

def trigger_gitlab_pipeline(iam_token, instance_group_id):
    env = os.getenv('ENV')
    app = os.getenv('APP')
    service = os.getenv('SERVICE')
    subservice = os.getenv('SUBSERVICE')

    gitlab_branch = os.getenv('GITLAB_BRANCH')
    gitlab_project_id = os.getenv('GITLAB_PROJECT_ID')
    gitlab_token = os.getenv('GITLAB_TRIGGER_TOKEN')


    gitlab_trigger_url = f"https://gitlab.com/api/v4/projects/{gitlab_project_id}/trigger/pipeline"

    data = {
        'token': gitlab_token,
        'ref': gitlab_branch,
        'variables[ENV]': env,
        'variables[APP]': app,
        'variables[SERVICE]': service,
        'variables[IAM_TOKEN]': iam_token,
        'variables[INSTANCE_GROUP_ID]': instance_group_id
    }
    if subservice:
        data['variables[SUBSERVICE]'] = subservice

    response = requests.post(gitlab_trigger_url, data=data)
    if response.status_code in (200, 201):
        print("✅ GitLab pipeline triggered successfully.")
    else:
        print(f"❌ Failed to trigger GitLab pipeline: {response.status_code} {response.text}")