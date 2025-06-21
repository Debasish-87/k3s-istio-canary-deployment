#!/bin/bash

set -euo pipefail

# Colors for output
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Function to print section headers
section() {
    echo -e "\n${BOLD}▶️ $1${RESET}"
}

section "Setting Docker environment for K3s/Minikube"
if command -v minikube &> /dev/null; then
    eval "$(minikube docker-env)"
else
    echo "⚠️ Minikube not found. Assuming Docker is already configured for K3s."
fi

section "Building Docker images for app v1 and v2"
docker build -t myapp:v1 ./docker/app-v1
docker build -t myapp:v2 ./docker/app-v2

section "Deploying application manifests (v1, v2, and Service)"
kubectl apply -f manifests/app/ --validate=false

section "Installing Istio (demo profile)"
if ! command -v istioctl &> /dev/null; then
    echo "❌ istioctl not found! Please install Istio CLI from https://istio.io/latest/docs/setup/getting-started/#install"
    exit 1
fi
istioctl install --set profile=demo -y

section "Labeling 'default' namespace for Istio sidecar injection"
kubectl label namespace default istio-injection=enabled --overwrite

section "Restarting app pods to inject Istio sidecars"
kubectl delete pods -l app=my-app --ignore-not-found

section "Applying Istio Gateway, DestinationRule, VirtualService"
kubectl apply -f manifests/istio/ --validate=false

section "Deploying Istio Observability Addons (Grafana, Kiali, Prometheus, Jaeger)"
if [ -d "istio-1.26.2/samples/addons" ]; then
    kubectl apply -f istio-1.26.2/samples/addons
else
    echo "⚠️ Istio addons not found at: istio-1.26.2/samples/addons"
    echo "➡️ Download from: https://istio.io/latest/docs/ops/integrations/add-ons/"
fi

section "Waiting for observability tools to be ready"
kubectl wait --for=condition=ready pod -l app=grafana -n istio-system --timeout=120s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kiali -n istio-system --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=prometheus -n istio-system --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=jaeger -n istio-system --timeout=120s || true

section "Starting port-forwards for app and observability dashboards"

# Kill if already running
fuser -k 8080/tcp 20001/tcp 3000/tcp 9090/tcp 16686/tcp > /dev/null 2>&1 || true

# Port-forwards
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80 > /dev/null 2>&1 &
kubectl port-forward -n istio-system svc/kiali 20001:20001 > /dev/null 2>&1 &
kubectl port-forward -n istio-system svc/grafana 3000:3000 > /dev/null 2>&1 &
kubectl port-forward -n istio-system svc/prometheus 9090:9090 > /dev/null 2>&1 &
sleep 5

# App Health Check
if curl -s http://localhost:8080/ > /dev/null; then
    echo "✅ App is now accessible at: http://localhost:8080/"
else
    echo "⚠️ App not reachable at http://localhost:8080/ — please check pod logs or Istio config."
fi

section "🎉 Setup Complete"

cat <<EOF

🌐 Access the system:

🔹 App URL:           http://localhost:8080/
🔹 Grafana:           http://localhost:3000/
🔹 Kiali Dashboard:   http://localhost:20001/
🔹 Prometheus:        http://localhost:9090/
🔹 Monitor App:       ./monitor.sh (optional)

🧪 You can now simulate canary rollout using 'virtual-service.yaml'

EOF
