import os, sys, requests
from yandexcloud import SDK
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2_grpc import InstanceGroupServiceStub
from yandex.cloud.compute.v1.instancegroup.instance_group_service_pb2 import ListInstanceGroupInstancesRequest
from yandex.cloud.compute.v1.instance_service_pb2_grpc import InstanceServiceStub
from yandex.cloud.compute.v1.instance_service_pb2 import GetInstanceRequest

def main():
    iam_token = os.environ.get("IAM_TOKEN")
    if not iam_token:
        raise Exception("IAM_TOKEN env variable not set!")
    instance_group_id = os.environ.get('INSTANCE_GROUP_ID')
    if not instance_group_id:
        raise Exception("INSTANCE_GROUP_ID env variable not set!")

    sdk = SDK(token=None, iam_token=iam_token)
    group_client = sdk.client(InstanceGroupServiceStub)
    instance_client = sdk.client(InstanceServiceStub)

    instances = group_client.ListInstances(ListInstanceGroupInstancesRequest(instance_group_id=instance_group_id)).instances

    for inst in instances:
        info = instance_client.Get(GetInstanceRequest(instance_id=inst.instance_id))
        # Для всех инстансов — статус "false"
        new_status = "false"
        labels = dict(info.labels, deploy_status=new_status)
        url = f"https://compute.api.cloud.yandex.net/compute/v1/instances/{inst.instance_id}"
        body = {"updateMask": "labels", "labels": labels}
        headers = {"Authorization": f"Bearer {iam_token}", "Content-Type": "application/json"}

        response = requests.patch(url, headers=headers, json=body)
        if response.status_code in (200, 201):
            print(f"✅ Instance {inst.instance_id}: {new_status}")
        else:
            print(f"❌ Failed for {inst.instance_id}: {response.status_code} {response.text}")

if __name__ == "__main__":
    main()