LOCAL_IMAGE="kxi-da-single:local"
REMOTE_IMAGE="${DS_REGISTRY}kxi-da-single:${DS_TAG}"
BUILD_DIR="$(dirname "${BASH_SOURCE[0]}")/../images/kxi-da-single"
BUILD_ARGS=(--build-arg DS_REGISTRY="$DS_REGISTRY" --build-arg DS_TAG="$DS_TAG")

do_run() {
  docker run --rm -it \
        --name kx-db-da \
        --memory "${DS_DA_MEM_LIMIT:-0}" \
        --network kx-db \
        -p 5080:5080 \
        -p 5081:5081 \
        -p 5082:5082 \
        -p 5083:5083 \
        -v "$(pwd)/data/db:/db" \
        -v "$(pwd)/data/logs:/logs" \
        -e KDB_LICENSE_B64 \
        -e KDB_K4LICENSE_B64 \
        -e KXDB_ENABLED=true \
        -e KXI_NAME=dap \
        -e KXI_SC=dap \
        -e KXI_PORT=5080 \
        -e RT_LOG_PATH=/logs/da \
        -e KXI_LOG_LEVELS=default:trace \
        -e KXI_SCHEMA_OWNERSHIP=internal \
        -e RT_TOPIC_PREFIX=rt- \
        -e RT_REPLICAS=1 \
        -e KXI_SECURE_ENABLED=false \
        -e KXI_LATE_DATA=true \
        -e KXI_LOG_FORMAT=text \
        -e KXI_SG_RC_ADDR=kx-db-rc:5050 \
        -e KXI_SM_ADDR=kx-db-sm:20001 \
        "$1"
}
