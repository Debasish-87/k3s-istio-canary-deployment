#!/bin/bash

set -euo pipefail

# Colors
BOLD=$(tput bold)
RESET=$(tput sgr0)

section() {
    echo -e "\n${BOLD}🛑 $1${RESET}"
}

section "Killing all port-forwards (8080, 20001, 3000, 9090, 16686)"
fuser -k 8080/tcp 20001/tcp 3000/tcp 9090/tcp 16686/tcp > /dev/null 2>&1 || true

section "Deleting app deployments and service"
kubectl delete -f manifests/app/ --ignore-not-found

section "Deleting Istio Gateway, VirtualService, DestinationRule"
kubectl delete -f manifests/istio/ --ignore-not-found

section "Unlabeling default namespace"
kubectl label namespace default istio-injection- --overwrite || true

section "Deleting Istio addons (Grafana, Kiali, Prometheus, Jaeger)"
if [ -d "istio-1.26.2/samples/addons" ]; then
    kubectl delete -f istio-1.26.2/samples/addons --ignore-not-found
fi

section "Deleting Istio control plane"
istioctl uninstall --purge -y || true
kubectl delete namespace istio-system --ignore-not-found

section "🧹 Cleanup complete!"

cat <<EOF

✅ All deployments, services, Istio configs, and dashboards have been removed.

You can now:
- Re-run setup.sh to reinstall
- Stop K3s or Minikube if desired

🔻 Stop K3s:
  sudo systemctl stop k3s

🔻 Stop Minikube:
  minikube stop

EOF
