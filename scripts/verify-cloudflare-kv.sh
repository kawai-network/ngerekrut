#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID is required}"
: "${CLOUDFLARE_KV_NAMESPACE_ID:?CLOUDFLARE_KV_NAMESPACE_ID is required}"
: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN is required}"

API_BASE="https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/storage/kv/namespaces/${CLOUDFLARE_KV_NAMESPACE_ID}"

read_json() {
  local key="$1"
  curl -sS \
    -X GET \
    "${API_BASE}/values/${key}" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
}

list_keys() {
  local prefix="$1"
  curl -sS \
    -G \
    "${API_BASE}/keys" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    --data-urlencode "prefix=${prefix}" \
    --data-urlencode "limit=100"
}

echo "Listing jobs..."
list_keys "job:" | jq .

echo
echo "Reading job:job_backend_001..."
read_json "job:job_backend_001" | jq .

echo
echo "Reading candidates for job_backend_001..."
list_keys "job:job_backend_001:candidate:" | jq .

echo
echo "Reading shortlist..."
read_json "job:job_backend_001:shortlist:latest" | jq .

