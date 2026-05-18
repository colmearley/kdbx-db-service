LOCAL_IMAGE="kxi-sg-agg:local"
REMOTE_IMAGE="${DS_REGISTRY}kxi-sg-agg:${DS_TAG}"
BUILD_DIR="$(dirname "${BASH_SOURCE[0]}")/../images/kxi-sg-agg"
BUILD_ARGS=(--build-arg DS_REGISTRY="$DS_REGISTRY" --build-arg DS_TAG="$DS_TAG")

do_run() {
  docker run --rm -it \
        --name kx-db-agg \
        --memory "${DS_OTHER_MEM_LIMIT:-0}" \
        --network kx-db \
        -p 15060:5060 \
        -e KDB_LICENSE_B64 \
        -e KDB_K4LICENSE_B64 \
        -e KXDB_ENABLED=true \
        -e KXI_NAME=sg_agg \
        -e KXI_PORT=5060 \
        -e KXI_LOG_LEVELS=default:trace \
        -e KXI_SCHEMA_OWNERSHIP=internal \
        -e KXI_SECURE_ENABLED=false \
        -e KXI_LATE_DATA=true \
        -e KXI_LOG_FORMAT=text \
        -e KXI_SG_RC_ADDR=kx-db-rc:5050 \
        "$1"
}
