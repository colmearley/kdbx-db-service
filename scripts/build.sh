#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../.env"

SERVICES=(rt sm da rc agg gw)
SERVICE=${1:-}
shift || true
EXTRA_ARGS=("$@")

usage() {
  echo "Usage: build.sh <service|all> [docker build args...]"
  echo "Services: ${SERVICES[*]}"
  exit 1
}

build_service() {
  local svc=$1
  local script="$(dirname "$0")/$svc.sh"
  [[ -f "$script" ]] || { echo "Unknown service: $svc"; usage; }
  source "$script"
  local images_dir="$(dirname "$0")/../images"
  echo "Building $LOCAL_IMAGE from $BUILD_DIR..."
  docker build "${BUILD_ARGS[@]}" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} -f "$BUILD_DIR/Dockerfile" -t "$LOCAL_IMAGE" "$images_dir"
}

[[ -z "$SERVICE" ]] && usage

if [[ "$SERVICE" == "all" ]]; then
  for svc in "${SERVICES[@]}"; do
    build_service "$svc"
  done
else
  build_service "$SERVICE"
fi
