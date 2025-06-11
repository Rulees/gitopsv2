import os, time, json, jwt, requests
from yandexcloud import SDK
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2_grpc import InstanceGroupServiceStub
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2 import ListInstanceGroupInstancesRequest
from yandex.cloud.compute.v1.instance_service_pb2_grpc import InstanceServiceStub
from yandex.cloud.compute.v1.instance_service_pb2 import UpdateInstanceMetadataRequest




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
        client = sdk.client(InstanceGroupServiceStub)

        instance_group_id = os.environ.get('INSTANCE_GROUP_ID')
        print(f"instance_group_id: {instance_group_id}")

        while True:  # Loop to call every 10 seconds
            instances = client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances

            awaiting_instances = [
                inst for inst in instances if inst.status == "AWAITING_STARTUP_DURATION" and not is_tagged(inst)
            ]

            if awaiting_instances:
                print(f"🔄 Found {len(awaiting_instances)} 'awaiting-startup' instances.")
                
                # Wait for 10 seconds to allow more instances to come online
                print("⏳ Waiting for 10 seconds to check for more instances...")
                time.sleep(10)

                # Re-poll the instances after 10 seconds to get any remaining ones
                instances = client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances
                awaiting_instances = [
                    inst for inst in instances if inst.status == "AWAITING_STARTUP_DURATION" and not is_tagged(inst)
                ]
                
                # Mark instances with the "deployed=true" tag
                for inst in awaiting_instances:
                    add_tag_to_instance(inst, "deployed=true")

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

def is_tagged(instance):
    return instance.labels.get("deployed") == "true"


def add_tag_to_instance(instance, tag):
    client = SDK().client(InstanceServiceStub)
    instance_id = instance.instance_id  # FIX: use instance.instance_id, not instance.id
    print(f"Adding tag '{tag}' to instance {instance_id}")
    # FIX: Use upsert dict, not labels list
    key, value = tag.split("=", 1)
    client.UpdateMetadata(UpdateInstanceMetadataRequest(instance_id=instance_id, upsert={key: value}))


def trigger_gitlab_pipeline():
    env = os.getenv('ENV')
    app = os.getenv('APP')
    service = os.getenv('SERVICE')

    gitlab_branch = os.getenv('GITLAB_BRANCH')
    gitlab_project_id = os.getenv('GITLAB_PROJECT_ID')
    gitlab_token = os.getenv('GITLAB_TRIGGER_TOKEN')

    gitlab_trigger_url = f"https://gitlab.com/api/v4/projects/{gitlab_project_id}/ref/{gitlab_branch}/trigger/pipeline?token={gitlab_token}"

    data = {
        "variables": {
            "ENV": env,
            "APP": app,
            "SERVICE": service
        }
    }

    # Send the request to GitLab webhook
    response = requests.post(gitlab_trigger_url, data=data)
    if response.status_code in (200, 201):
        print("✅ GitLab pipeline triggered successfully.")
    else:
        print(f"❌ Failed to trigger GitLab pipeline: {response.text}")
