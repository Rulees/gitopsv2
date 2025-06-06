import os, time, json, jwt
from yandexcloud import SDK
from datetime import timedelta
from yandex.cloud.serverless.containers.v1.container_service_pb2 import DeployContainerRevisionRequest
from yandex.cloud.serverless.containers.v1.container_service_pb2_grpc import ContainerServiceStub


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

        print("🟡 Reading container config.....")
        cfg_path = os.path.join(os.path.dirname(__file__), "container_config.json")
        with open(cfg_path, "r") as f:
            cfg = json.load(f)

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
        client = sdk.client(ContainerServiceStub)

        # Преобразовать "15s" в timedelta
        timeout_str = cfg["execution_timeout"]
        timeout = timedelta(seconds=int(timeout_str.rstrip("s")))

        print(f"🚀 Deploying revision for container: {cfg['container_id']}")
        op = client.DeployRevision(DeployContainerRevisionRequest(
            container_id=cfg["container_id"],
            description=cfg["description"],
            execution_timeout=timeout,
            service_account_id=cfg["service_account_id"],
            image_spec=cfg["image_spec"],
            resources=cfg["resources"],
            concurrency=cfg["concurrency"],
            provision_policy=cfg["provision_policy"]
        ))


        print("✅ DeployRevision triggered")
        return {
            "statusCode": 200,
            "body": f"✅ Deployed container {cfg['container_id']}"
        }

    except Exception as e:
        print(f"❌ Error: {e}")
        return {
            "statusCode": 500,
            "body": f"❌ Exception: {str(e)}"
        }
