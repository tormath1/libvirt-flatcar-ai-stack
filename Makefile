GIE_VERSION = "v1.6.2"
CILIUM_VERSION = "1.21.0-pre.4"
METALLB_VERSION = "0.16.2"

.PHONY: cluster
cluster:
	@tofu apply -auto-approve
	@mkdir -p ~/.kube
	@mv --interactive admin.conf ~/.kube/config || true

.PHONY: cni
cni: cluster
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_backendtlspolicies.yaml
	kubectl apply --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.6.3/config/crd/standard/gateway.networking.k8s.io_tlsroutes.yaml

	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/$(GIE_VERSION)/manifests.yaml

	helm upgrade --install cilium cilium/cilium --version $(CILIUM_VERSION) \
	   --namespace kube-system \
	   --set kubeProxyReplacement=true \
	   --set gatewayAPI.enabled=true \
	   --set gatewayAPI.inferenceExtension.enabled=true

	cilium status --wait

.PHONY: lb
lb: cni
	helm upgrade --install metallb metallb/metallb --version $(METALLB_VERSION) \
	  --namespace metallb-system \
	  --create-namespace \
	  --wait \
	  --timeout 5m
	kubectl apply -f ./manifests/metal.yaml
	kubectl apply -f ./manifests/gateway.yaml

.PHONY: inference
inference:
	kubectl apply -f ./manifests/kaito.yaml

.PHONY: ai-manager
ai-manager: inference

	# Block AgentDeployment CREATE/UPDATE before webhook versions can mix (phase 1)
	kubectl apply -f https://raw.githubusercontent.com/ai-runway/airunway/main/deploy/agentdeployment-webhook-guard.yaml

	# Install CRDs and roll out without AgentDeployment admission routes (phase 2)
	kubectl apply -f https://raw.githubusercontent.com/ai-runway/airunway/main/deploy/controller.yaml

	# Force a new ReplicaSet even when the image tag string is unchanged, then wait
	# until every webhook Service endpoint runs the replacement pods.
	kubectl rollout restart deployment/airunway-controller-manager -n airunway-system
	kubectl rollout status deployment/airunway-controller-manager -n airunway-system --timeout=5m

	# Activate the complete validator/mutator set, then unblock writes (phase 3).
	# Wait until cert-controller injects the serving CA before deleting the guard.
	kubectl apply -f https://raw.githubusercontent.com/ai-runway/airunway/main/deploy/agentdeployment-webhook.yaml
	kubectl wait secret/airunway-webhook-server-cert -n airunway-system --for=jsonpath='{.data.ca\.crt}' --timeout=5m
	AIRUNWAY_WEBHOOK_CA_BUNDLE="$$(kubectl get secret/airunway-webhook-server-cert -n airunway-system -o jsonpath='{.data.ca\.crt}')"; \
	test -n "$${AIRUNWAY_WEBHOOK_CA_BUNDLE}"; \
	kubectl wait mutatingwebhookconfiguration/airunway-mutating-webhook-configuration --for="jsonpath={.webhooks[?(@.name==\"magentdeployment-v1alpha1.kb.io\")].clientConfig.caBundle}=$${AIRUNWAY_WEBHOOK_CA_BUNDLE}" --timeout=5m; \
	kubectl wait validatingwebhookconfiguration/airunway-validating-webhook-configuration --for="jsonpath={.webhooks[?(@.name==\"vagentdeployment-v1alpha1.kb.io\")].clientConfig.caBundle}=$${AIRUNWAY_WEBHOOK_CA_BUNDLE}" --timeout=5m
	kubectl delete --ignore-not-found=true -f https://raw.githubusercontent.com/ai-runway/airunway/main/deploy/agentdeployment-webhook-guard.yaml

	# Kaito provider
	kubectl apply -f ./manifests/ai-manager-kaito.yaml

.PHONY: models
models: ai-manager
	kubectl apply -f ./manifests/model-llama.yaml
	kubectl apply -f ./manifests/model-gemma.yaml
	kubectl get modeldeployments -n kaito-workspace

.PHONY: ai-manager-dashboard
ai-manager-dashboard:
	# Install dashboard UI (optional)
	kubectl apply -f ./manifests/manager-dashboard.yaml
	# TODO: Expose this via Gateway API
	kubectl port-forward -n airunway-system svc/airunway 3001:80

.PHONY: ssh
ssh:
	ssh core@$$(tofu output -json | jq -r .control_plane_endpoint.value)
