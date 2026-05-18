LOCAL_IMAGE="kxi-sg-rc:local"
REMOTE_IMAGE="${DS_REGISTRY}kxi-sg-rc:${DS_TAG}"
BUILD_DIR="$(dirname "${BASH_SOURCE[0]}")/../images/kxi-sg-rc"
BUILD_ARGS=(--build-arg DS_REGISTRY="$DS_REGISTRY" --build-arg DS_TAG="$DS_TAG")

do_run() {
  docker run --rm -it \
        --name kx-db-rc \
        --memory "${DS_OTHER_MEM_LIMIT:-0}" \
        --network kx-db \
        -p 5050:5050 \
        -e KDB_LICENSE_B64 \
        -e KDB_K4LICENSE_B64 \
        -e KXDB_ENABLED=true \
        -e KXI_NAME=sg_rc \
        -e KXI_PORT=5050 \
        -e KXI_LOG_LEVELS=default:trace \
        -e KXI_SCHEMA_OWNERSHIP=internal \
        -e KXI_SECURE_ENABLED=false \
        -e KXI_LATE_DATA=true \
        -e KXI_LOG_FORMAT=text \
        "$1"
}
