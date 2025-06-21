# 🚀 k3s-istio-canary-deployment

A **Cloud-Native Microservices Deployment Demo** using lightweight Kubernetes with **K3s**, integrated with **Istio Service Mesh** for intelligent traffic management and **Canary Deployment**. This project features two versions of a Dockerized Node.js app (`v1` and `v2`) with controlled traffic routing using Istio.

---

## 📂 Project Structure

```

k3s-istio-canary-deployment/
├── canary-strategy.md           # Notes on deployment strategy
├── docker/
│   ├── app-v1/                  # Node.js v1
│   │   ├── Dockerfile
│   │   └── index.js
│   └── app-v2/                  # Node.js v2
│       ├── Dockerfile
│       └── index.js
├── istio-1.26.2/                # Istio CLI and sample add-ons
├── manifests/
│   ├── app/
│   │   ├── deployment-v1.yaml   # Kubernetes Deployment for app v1
│   │   ├── deployment-v2.yaml   # Kubernetes Deployment for app v2
│   │   └── service.yaml         # Shared Kubernetes Service
│   └── istio/
│       ├── gateway.yaml         # Istio Gateway
│       ├── virtual-service.yaml# Istio VirtualService for routing
│       └── destination-rule.yaml# Istio DestinationRule for subsets
├── monitor.sh                   # Optional monitoring script (custom)
├── setup.sh                     # Automated setup script (optional)
└── readme.md                    # 📘 This file

````

---

## 🧰 Tools & Technologies

| Tool       | Description                                |
|------------|--------------------------------------------|
| **K3s**    | Lightweight Kubernetes for local cluster    |
| **Istio**  | Service mesh for traffic control & security |
| **Docker** | Containerizes Node.js apps (`v1`, `v2`)     |
| **kubectl**| Kubernetes command-line tool                |
| **Node.js**| Backend web app (different versions)        |

---

## 📦 App Overview

You deploy two versions of a Node.js app:

- **v1**: Stable production version.
- **v2**: Canary version (small traffic for testing).

Using **Istio VirtualService**, you can split traffic like:

```yaml
- destination:
    host: my-app
    subset: v1
  weight: 80
- destination:
    host: my-app
    subset: v2
  weight: 20
````

---

## ⚙️ Setup Guide

### 🔧 Prerequisites

* Docker installed
* K3s installed (or install via: `curl -sfL https://get.k3s.io | sh -`)
* `kubectl` installed and configured
* `istioctl` CLI (from `istio-1.26.2/` directory)

---

### 1️⃣ Start K3s and Set Context

```bash
sudo systemctl start k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

---

### 2️⃣ Install Istio

```bash
cd istio-1.26.2/
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
```

---

### 3️⃣ Build Docker Images

```bash
# From project root
docker build -t app:v1 ./docker/app-v1
docker build -t app:v2 ./docker/app-v2
```

> 📝 For K3s (containerd), save & import:

```bash
docker save app:v1 > app-v1.tar
docker save app:v2 > app-v2.tar
sudo k3s ctr images import app-v1.tar
sudo k3s ctr images import app-v2.tar
```

---

### 4️⃣ Deploy to K3s

```bash
# Apply app deployments & service
kubectl apply -f manifests/app/

# Apply Istio config
kubectl apply -f manifests/istio/
```

---

## 🌐 Access the App

```bash
kubectl get svc istio-ingressgateway -n istio-system
```

> Use the EXTERNAL-IP (or `localhost` if using port-forward) to access:

```bash
curl http://<EXTERNAL-IP>/
```

You should see a response from either `v1` or `v2`, based on the configured weight.

---

## 🧠 Canary Strategy

A **Canary Deployment** sends a small % of user traffic to a new version (`v2`) to monitor behavior before full rollout.

* If stable: increase weight to `v2`
* If errors: rollback instantly to `v1`

You can edit `virtual-service.yaml` to adjust routing:

```yaml
  route:
  - destination:
      host: my-app
      subset: v1
    weight: 90
  - destination:
      host: my-app
      subset: v2
    weight: 10
```

Apply changes:

```bash
kubectl apply -f manifests/istio/virtual-service.yaml
```

---

## 📊 Monitoring (Optional)

Istio provides dashboards (enable if needed):

```bash
kubectl apply -f istio-1.26.2/samples/addons/
```

Access tools with port forwarding:

```bash
# Kiali UI
kubectl port-forward svc/kiali -n istio-system 20001:20001
```

| Tool           | URL                                              |
| -------------- | ------------------------------------------------ |
| **Kiali**      | [http://localhost:20001](http://localhost:20001) |
| **Jaeger**     | [http://localhost:16686](http://localhost:16686) |
| **Grafana**    | [http://localhost:3000](http://localhost:3000)   |
| **Prometheus** | [http://localhost:9090](http://localhost:9090)   |

---

## ✅ Sample Output

```bash
$ curl http://<INGRESS-IP>/
Welcome to App Version v1

$ curl http://<INGRESS-IP>/
Welcome to App Version v2
```

Run this multiple times to observe traffic switching!

---


### 🎯 Canary Traffic Split Verification via VirtualService

We tested Istio Canary deployment by adjusting traffic weights between `v1` and `v2` using **VirtualService** and observed the success rate using **Kiali Dashboard**.

---

#### ✅ Case 1: `v1` = 80%, `v2` = 20%

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
    - "*"
  gateways:
    - my-app-gateway
  http:
    - route:
        - destination:
            host: my-app
            subset: v1
          weight: 80
        - destination:
            host: my-app
            subset: v2
          weight: 20
```

📸 Screenshot from Kiali (100% Success Rate):
![v1-80-v2-20](screenshots/kiali-success-v1-80-v2-20.png)

---

#### ✅ Case 2: `v1` = 20%, `v2` = 80%

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
    - "*"
  gateways:
    - my-app-gateway
  http:
    - route:
        - destination:
            host: my-app
            subset: v1
          weight: 20
        - destination:
            host: my-app
            subset: v2
          weight: 80
```

📸 Screenshot from Kiali (Again, 100% Success Rate):
![v1-20-v2-80](screenshots/kiali-success-v1-20-v2-80.png)

---

### ✅ Conclusion

No matter how traffic was split between stable (`v1`) and canary (`v2`), **Istio routed requests reliably with 100% success** — proving the stability of our application and the reliability of Istio's traffic management.

---

## 📘 References

* [Istio Docs](https://istio.io/latest/docs/)
* [K3s Docs](https://docs.k3s.io/)
* [Canary Deployments](https://learn.microsoft.com/en-us/devops/deliver/what-is-canary-deployment)

---

## 👨‍💻 Author

**Debasish Mohanty**
DevSecOps | Kubernetes | SRE | Cloud Security
[GitHub](https://github.com/Debasish-87) • [LinkedIn](https://linkedin.com/in/debasish8787)

---

