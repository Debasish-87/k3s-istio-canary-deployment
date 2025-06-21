## 📘 Canary Deployment Strategy in Kubernetes using Istio

### 🔰 Overview

Canary deployments enable gradual rollouts of new application versions by routing a small percentage of traffic to the new version while the rest continues to use the stable version. This helps mitigate the risk of introducing bugs or performance issues.

---

### 📦 Tools Used

| Tool           | Purpose                               |
| -------------- | ------------------------------------- |
| **Kubernetes** | Container orchestration               |
| **Istio**      | Traffic splitting and routing control |
| **Prometheus** | Metrics collection and alerting       |
| **Grafana**    | Visualizing app and service metrics   |
| **Jaeger**     | Distributed tracing for service calls |
| **Kiali**      | Istio observability and service map   |

---

### 🚦 Canary Deployment Flow

1. **Build Docker images** for `v1` and `v2` of the app.
2. **Deploy both versions** using Kubernetes `Deployment` and `Service` resources.
3. **Apply Istio VirtualService** and `DestinationRule` to split traffic (e.g., 90% to v1, 10% to v2).
4. **Monitor metrics and tracing** using Grafana and Jaeger.
5. **If v2 is stable**, increase traffic gradually or promote v2 to full traffic.
6. **If issues are detected**, rollback by routing all traffic back to v1.

---

### 🧱 Istio YAML Configuration

#### DestinationRule (for version subsets)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app.default.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

#### VirtualService (for traffic routing)

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
      weight: 90
    - destination:
        host: my-app
        subset: v2
      weight: 10
```

---

### 📊 Monitoring During Canary

| Tool       | What to Monitor                            |
| ---------- | ------------------------------------------ |
| Grafana    | CPU, memory, request count, latency trends |
| Prometheus | Success/error rate of v1 vs v2             |
| Jaeger     | Slow/misbehaving traces in v2              |
| Kiali      | Real-time traffic split & error flow       |

---

### 🔁 Roll Forward / Roll Back

* **To Roll Forward (Promote v2 to 100%)**:

```yaml
route:
  - destination:
      host: my-app
      subset: v1
    weight: 0
  - destination:
      host: my-app
      subset: v2
    weight: 100
```

* **To Roll Back (Send all traffic to v1)**:

```yaml
route:
  - destination:
      host: my-app
      subset: v1
    weight: 100
  - destination:
      host: my-app
      subset: v2
    weight: 0
```

---

### 🛡️ Best Practices

* Always monitor metrics and alerts before increasing v2 traffic.
* Use **Alertmanager** to trigger notifications on anomalies.
* Automate rollback using Prometheus alert thresholds.
* Gradually increment v2 traffic: 10% → 25% → 50% → 100%.

---

### ✅ Summary

| Step | Description                            |
| ---- | -------------------------------------- |
| 1    | Deploy both v1 and v2                  |
| 2    | Configure traffic split in Istio       |
| 3    | Monitor app behavior (Grafana, Jaeger) |
| 4    | Decide: Promote, Pause, or Rollback    |

---
