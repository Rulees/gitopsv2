import os, time, json, jwt, requests
from yandexcloud import SDK
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2_grpc import InstanceGroupServiceStub
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2 import ListInstanceGroupInstancesRequest
from yandex.cloud.compute.v1.instance_service_pb2_grpc import InstanceServiceStub
from yandex.cloud.compute.v1.instance_service_pb2 import UpdateInstanceMetadataRequest, GetInstanceRequest




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

        sdk = SDK(token=None, iam_token=None, jwt=jwt_token)
        group_client = sdk.client(InstanceGroupServiceStub)
        instance_client = sdk.client(InstanceServiceStub)

        instance_group_id = os.environ.get('INSTANCE_GROUP_ID')
        print(f"instance_group_id: {instance_group_id}")

        while True:  # Loop to call every 10 seconds
            instances = group_client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances
            awaiting_instances = []

            for inst in instances:
                # print(f"Instance: {inst.instance_id}, status: {inst.status}, labels: {inst.metadata}")
                info = instance_client.Get(GetInstanceRequest(instance_id=inst.instance_id))
                # print(f"Instance: {inst.instance_id}, status: {inst.status}, metadata: {getattr(inst, 'metadata', {})}, labels: {getattr(inst, 'labels', {})}")
                deployed = info.metadata.get("deployed")
                print(f"Instance: {inst.instance_id}, status: {inst.status}, metadata: {info.metadata}")

                if inst.status == 21 and deployed != "true":
                    awaiting_instances.append(info)

            if awaiting_instances:
                print(f"🔄 Found {len(awaiting_instances)} 'awaiting-startup' instances (status==21, not deployed).")
                print("⏳ Waiting for 10 seconds to check for more instances...")
                time.sleep(10)

                # ВТОРОЙ ПРОХОД: повторная проверка через 10 секунд
                instances = group_client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances
                awaiting_instances = []
                for inst in instances:
                    info = instance_client.Get(GetInstanceRequest(instance_id=inst.instance_id))
                    deployed = info.metadata.get("deployed")
                    if inst.status == 21 and deployed != "true":
                        awaiting_instances.append(info)

                # Теперь обновляем metadata и деплоим
                if awaiting_instances:
                    for info in awaiting_instances:
                        print(f"Marking instance {info.id} as deployed")
                        instance_client.UpdateMetadata(UpdateInstanceMetadataRequest(
                            instance_id=info.id,
                            upsert={"deployed": "true"}
                        ))
                    print("✅ Instances processed and tagged.")
                    trigger_gitlab_pipeline()

            else:
                print("❌ No new 'awaiting-startup' instances found.")

            print("⏳ Waiting for 10 seconds before the next check...")
            time.sleep(10)

    except Exception as e:
        print(f"❌ Error: {e}")
        return {
            "statusCode": 500,
            "body": f"❌ Exception: {str(e)}"
        }

def trigger_gitlab_pipeline():
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
    }
    if subservice:
        data['variables[SUBSERVICE]'] = subservice

    response = requests.post(gitlab_trigger_url, data=data)
    if response.status_code in (200, 201):
        print("✅ GitLab pipeline triggered successfully.")
    else:
        print(f"❌ Failed to trigger GitLab pipeline: {response.status_code} {response.text}")