KUBE_NAMESPACE ?= default
HELM_RELEASE ?= test
INGRESS_HOST ?= tango-example.minikube.local

.PHONY: k8s show lint deploy delete logs describe mkcerts localip namespace test help
.DEFAULT_GOAL := help

k8s: ## Which kubernetes are we connected to
	@echo "Kubernetes cluster-info:"
	@kubectl cluster-info
	@echo ""
	@echo "kubectl version:"
	@kubectl version
	@echo ""
	@echo "Helm version:"
	@helm version --client

namespace: ## create the kubernetes namespace
	kubectl describe namespace $(KUBE_NAMESPACE) || kubectl create namespace $(KUBE_NAMESPACE)

deploy: namespace  ## deploy the helm chart
	@helm template charts/tango-chart-example/ --name $(HELM_RELEASE) \
				 --namespace $(KUBE_NAMESPACE) \
         --tiller-namespace $(KUBE_NAMESPACE) \
				 --set ingress.hostname=$(INGRESS_HOST) | kubectl -n $(KUBE_NAMESPACE) apply -f -

show: ## show the helm chart
	@helm template charts/tango-chart-example/ --name $(HELM_RELEASE) \
				 --namespace $(KUBE_NAMESPACE) \
         --tiller-namespace $(KUBE_NAMESPACE) \
				 --set ingress.hostname=$(INGRESS_HOST)

lint: ## lint check the helm chart
	@helm lint charts/tango-chart-example/ \
				 --namespace $(KUBE_NAMESPACE) \
         --tiller-namespace $(KUBE_NAMESPACE) \
				 --set ingress.hostname=$(INGRESS_HOST)

delete: ## delete the helm chart release
	@helm template charts/tango-chart-example/ --name $(HELM_RELEASE) \
				 --namespace $(KUBE_NAMESPACE) \
         --tiller-namespace $(KUBE_NAMESPACE) \
				 --set ingress.hostname=$(INGRESS_HOST) | kubectl -n $(KUBE_NAMESPACE) delete -f -

describe: ## describe Pods executed from Helm chart
	@for i in `kubectl -n $(KUBE_NAMESPACE) get pods -l app.kubernetes.io/instance=$(HELM_RELEASE) -o=name`; \
	do echo "---------------------------------------------------"; \
	echo "Describe for $${i}"; \
	echo kubectl -n $(KUBE_NAMESPACE) describe $${i}; \
	echo "---------------------------------------------------"; \
	kubectl -n $(KUBE_NAMESPACE) describe $${i}; \
	echo "---------------------------------------------------"; \
	echo ""; echo ""; echo ""; \
	done

logs: ## show Helm chart POD logs
	@for i in `kubectl -n $(KUBE_NAMESPACE) get pods -l app.kubernetes.io/instance=$(HELM_RELEASE) -o=name`; \
	do \
	echo "---------------------------------------------------"; \
	echo "Logs for $${i}"; \
	echo kubectl -n $(KUBE_NAMESPACE) logs $${i}; \
	echo kubectl -n $(KUBE_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(KUBE_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"`; do \
	RES=`kubectl -n $(KUBE_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "initContainer: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "Main Pod logs for $${i}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(KUBE_NAMESPACE) get $${i} -o jsonpath="{.spec.containers[*].name}"`; do \
	RES=`kubectl -n $(KUBE_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "Container: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "---------------------------------------------------"; \
	echo ""; echo ""; echo ""; \
	done

localip:  ## set local Minikube IP in /etc/hosts file for Ingress $(INGRESS_HOST)
	@new_ip=`minikube ip` && \
	existing_ip=`grep $(INGRESS_HOST) /etc/hosts || true` && \
	echo "New IP is: $${new_ip}" && \
	echo "Existing IP: $${existing_ip}" && \
	if [ -z "$${existing_ip}" ]; then echo "$${new_ip} $(INGRESS_HOST)" | sudo tee -a /etc/hosts; \
	else sudo perl -i -ne "s/\d+\.\d+.\d+\.\d+/$${new_ip}/ if /$(INGRESS_HOST)/; print" /etc/hosts; fi && \
	echo "/etc/hosts is now: " `grep $(INGRESS_HOST) /etc/hosts`

mkcerts:  ## Make dummy certificates for $(INGRESS_HOST) and Ingress
	openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
	   -keyout charts/tango-chart-example/secrets/tls.key \
		 -out charts/tango-chart-example/secrets/tls.crt \
		 -subj "/CN=$(INGRESS_HOST)/O=Minikube"

test:  ## curl test Tango REST API - https://tango-controls.readthedocs.io/en/latest/development/advanced/rest-api.html#tango-rest-api-implementations
	@echo "---------------------------------------------------"
	@echo "test http:"
	curl -u "tango-cs:tango" -XGET http://$(INGRESS_HOST)/tango/rest/rc4/hosts/databaseds-tango-chart-example-$(HELM_RELEASE)/10000 || \
	curl -vvv -u "tango-cs:tango" -XGET http://$(INGRESS_HOST)/tango/rest/rc4/hosts/databaseds-tango-chart-example-$(HELM_RELEASE)/10000
	@echo "", echo ""
	@echo "---------------------------------------------------"
	@echo "test https:"
	curl -k -u "tango-cs:tango" -XGET https://$(INGRESS_HOST)/tango/rest/rc4/hosts/databaseds-tango-chart-example-$(HELM_RELEASE)/10000 || \
	curl -vvv -k -u "tango-cs:tango" -XGET https://$(INGRESS_HOST)/tango/rest/rc4/hosts/databaseds-tango-chart-example-$(HELM_RELEASE)/10000
	@echo ""

help:  ## show this help.
	@echo "make targets:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""; echo "make vars (+defaults):"
	@grep -E '^[0-9a-zA-Z_-]+ \?=.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = " \?\= "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
