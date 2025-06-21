#!/bin/bash
set -e

GRAFANA_URL="http://localhost:3000"
AUTH="admin:admin" 

for file in dashboards/*.json; do
  echo "⏳ Uploading $file to Grafana..."

  curl -s -u "$AUTH" -X POST \
    -H "Content-Type: application/json" \
    -d "{\"dashboard\": $(cat "$file"), \"overwrite\": true}" \
    "$GRAFANA_URL/api/dashboards/db"

  echo "✅ Uploaded: $file"
done

echo -e "\n🎉 All dashboards have been uploaded to Grafana!"

