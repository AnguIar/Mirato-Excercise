import os
import json
import base64
from flask import Flask, request, jsonify

app = Flask(__name__)

DEFAULT_RESOURCES = {
    "requests": {
        "cpu": os.getenv("DEFAULT_CPU_REQUEST", "500m"),
        "memory": os.getenv("DEFAULT_MEMORY_REQUEST", "512Mi")
    },
    "limits": {
        "cpu": os.getenv("DEFAULT_CPU_LIMIT", "1000m"),
        "memory": os.getenv("DEFAULT_MEMORY_LIMIT", "1Gi")
    }
}

def mutate_resources(resources, base_path, container_index):
    patches = []

    # If "requests" is not defined, add it with default values
    if "requests" not in resources:
        patches.append({
            "op": "add",
            "path": f"{base_path}/resources/requests",
            "value": DEFAULT_RESOURCES["requests"]
        })
    
    # If "limits" is not defined, but "requests" is, and limits is smaller than requests, set limits equal to requests
    if "limits" not in resources:
        patches.append({
            "op": "add",
            "path": f"{base_path}/resources/limits",
            "value": {
                "cpu": max(DEFAULT_RESOURCES["requests"]["cpu"], resources.get("requests", {}).get("cpu", "0")),
                "memory": max(DEFAULT_RESOURCES["requests"]["memory"], resources.get("requests", {}).get("memory", "0"))
            }
        })
    
    # If "limits" is defined and is smaller than default "requests", update requests to match limits
    if "limits" in resources:
        if (
            resources["limits"].get("cpu", "0") < DEFAULT_RESOURCES["requests"]["cpu"] or
            resources["limits"].get("memory", "0") < DEFAULT_RESOURCES["requests"]["memory"]
        ):
            patches.append({
                "op": "replace",
                "path": f"{base_path}/resources/requests",
                "value": resources["limits"]
            })

    return patches


def mutate_pod(pod):
    patches = []
    containers = pod.get("spec", {}).get("containers", [])

    for i, container in enumerate(containers):
        resources = container.get("resources", {})
        patches.extend(mutate_resources(resources, f"/spec/containers/{i}", i))

    return patches


def mutate_deployment(deployment):
    patches = []
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])

    for i, container in enumerate(containers):
        resources = container.get("resources", {})
        patches.extend(mutate_resources(resources, f"/spec/template/spec/containers/{i}", i))

    return patches


@app.route("/mutate", methods=["POST"])
def mutate():
    request_data = request.get_json()
    obj = request_data["request"]["object"]
    patches = []

    kind = request_data["request"]["kind"]["kind"]

    if kind == "Pod":
        patches = mutate_pod(obj)
    elif kind == "Deployment":
        patches = mutate_deployment(obj)

    response = {
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": {
            "uid": request_data["request"]["uid"],
            "allowed": True,
            "patchType": "JSONPatch",
            "patch": base64.b64encode(json.dumps(patches).encode()).decode() if patches else None
        }
    }
    return jsonify(response)

if __name__ == "__main__":
    cert_path = '/etc/ssl/certs/tls.crt'
    key_path = '/etc/ssl/certs/tls.key'

    app.run(host="0.0.0.0", port=8080, ssl_context=(cert_path, key_path))