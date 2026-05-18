LOCAL_IMAGE="kxi-sg-gw:local"
REMOTE_IMAGE="${DS_REGISTRY}kxi-sg-gw:${DS_TAG}"
BUILD_DIR="$(dirname "${BASH_SOURCE[0]}")/../images/kxi-sg-gw"
BUILD_ARGS=(--build-arg DS_REGISTRY="$DS_REGISTRY" --build-arg DS_TAG="$DS_TAG")

do_run() {
  docker run --rm -it \
        --name kx-db-gw \
        --memory "${DS_OTHER_MEM_LIMIT:-0}" \
        --network kx-db \
        -p "${DS_PORT_QIPC:-5040}:5040" \
        -p "${DS_PORT_HTTP:-8080}:8080" \
        -e KXI_LOG_LEVELS=default:trace \
        -e KXI_SCHEMA_OWNERSHIP=external \
        -e KXI_SECURE_ENABLED=false \
        -e KXI_LATE_DATA=true \
        -e GATEWAY_QIPC_PORT=5040 \
        -e GATEWAY_HTTP_PORT=8080 \
        -e KXI_SG_SM_ADDR_db=kx-db-sm:20001 \
        -e KXI_SCOPE_AFFINITY=soft \
        -e KXI_LOG_FORMAT=text \
        -e KXI_SG_RC_ADDR=kx-db-rc:5050 \
        "$1"
}
