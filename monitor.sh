#!/bin/bash

echo "📡 Monitoring app traffic through Istio Ingress Gateway..."
for i in {1..100}; do
  echo -n "$i: "
  curl -s http://localhost:8080/
  echo
  sleep 0.2
done
echo "✅ Traffic monitoring complete."
echo "📊 You can analyze canary traffic split in Kiali or Grafana."
