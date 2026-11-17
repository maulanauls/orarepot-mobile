#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-SIT}"
FORMAT="${2:-apk}"

# Portable uppercase (macOS ships Bash 3.2 — no ${var^^})
ENVIRONMENT="$(printf '%s' "$ENVIRONMENT" | tr '[:lower:]' '[:upper:]')"

case "$ENVIRONMENT" in
  SIT|UAT|PROD) ;;
  *)
    echo "Usage: $0 SIT|UAT|PROD [apk|appbundle]" >&2
    exit 2
    ;;
esac

case "$FORMAT" in
  apk|appbundle) ;;
  *)
    echo "Format must be apk or appbundle" >&2
    exit 2
    ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ansible-playbook \
  -i ansible/inventory.ini \
  ansible/build.yml \
  -e "app_env=${ENVIRONMENT}" \
  -e "build_format=${FORMAT}"
