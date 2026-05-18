#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../.env"

SERVICES=(rt sm da rc agg gw)
SERVICE=${1:-}
MODE=${2:-}

usage() {
  echo "Usage: run.sh <service> [--local]"
  echo "Services: ${SERVICES[*]}"
  exit 1
}

[[ -z "$SERVICE" ]] && usage

script="$(dirname "$0")/$SERVICE.sh"
[[ -f "$script" ]] || { echo "Unknown service: $SERVICE"; usage; }
source "$script"

if [[ "$MODE" == "--local" ]]; then
  do_run "$LOCAL_IMAGE"
else
  do_run "$REMOTE_IMAGE"
fi
