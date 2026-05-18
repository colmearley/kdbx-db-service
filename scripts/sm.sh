LOCAL_IMAGE="kxi-sm-single:local"
REMOTE_IMAGE="${DS_REGISTRY}kxi-sm-single:${DS_TAG}"
BUILD_DIR="$(dirname "${BASH_SOURCE[0]}")/../images/kxi-sm-single"
BUILD_ARGS=(--build-arg DS_REGISTRY="$DS_REGISTRY" --build-arg DS_TAG="$DS_TAG")

do_run() {
  docker run --rm -it \
        --name kx-db-sm \
        --memory "${DS_SM_MEM_LIMIT:-0}" \
        --network kx-db \
        -p 20001:20001 \
        -p 20002:20002 \
        -p 20003:20003 \
        -p 20004:20004 \
        -v "$(pwd)/data/db:/db" \
        -v "$(pwd)/data/imports:/imports" \
        -v "$(pwd)/data/logs:/logs" \
        -e KDB_LICENSE_B64 \
        -e KDB_K4LICENSE_B64 \
        -e KXDB_ENABLED=true \
        -e KXI_NAME=sm \
        -e KXI_SC=SM \
        -e KXI_PORT=20001 \
        -e RT_LOG_PATH=/logs/sm \
        -e KXI_SM_OBJSTORE_CONVERSION=true \
        -e KXI_LOG_LEVELS=default:trace \
        -e KXI_SCHEMA_OWNERSHIP=internal \
        -e RT_TOPIC_PREFIX=rt- \
        -e RT_REPLICAS=1 \
        -e KXI_SECURE_ENABLED=false \
        -e KXI_LATE_DATA=true \
        -e KXI_LOG_FORMAT=text \
        "$1"
}
