# CNCF local AI stack

This repository is for demo purposes: DO NOT USE THIS IN PRODUCTION.

The idea is to show how to run a local AI stack with CNCF components only:
```
$ curl --silent http://192.168.122.200/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Gateway-Model-Name: llama-3.2-1b-instruct" \
  -d '{"model": "llama-3.2-1b-instruct", "messages": [{"role": "user", "content": "Hello"}]}' | jq '.choices | .[0].message.content'
"Hello! How can I assist you today?"

$ curl --silent http://192.168.122.200/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Gateway-Model-Name: gemma-2-2b-instruct" \
  -d '{"model": "gemma-2-2b-instruct", "messages": [{"role": "user", "content": "Hello"}]}' | jq '.choices | .[0].message.content'
"Hello! 👋  How can I help you today? 😊  \n"
```

## How to use it

Requirements:
* Libvirt host (local or remote)
* OpenTofu, Helm and Kubectl are in the "${PATH}"
* At least one public SSH key (`ssh_keys`) in `./terraform.tfvars`

### Setup the Kubernetes cluster

```bash
make lb
```

With this command, you will:
* deploy a simple Kubernetes cluster with 3 nodes powered by Flatcar (with auto-update enabled for kubernetes patch releases)
* setup CNI + Gateway API + Gateway API Inference extension with Cilium
* setup Metal LB

### Setup the AI stack

Once the cluster is up-and-running you can deploy the AI stack:
```
make models
```

With this command, you will:
* deploy Kaito for the inference
* deploy AI Runway as an AI Manager
* deploy two small models with Gateway API Inference Extension enabled

### Usage

Find the Gateway API endpoint:
```
$ kubectl get gateway
```

or use the dashboard directly:
```
$ make ai-manager-dashboard
```
