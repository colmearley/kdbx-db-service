LOCAL_IMAGE="kxi-rt:local"
REMOTE_IMAGE="${DS_REGISTRY:-}kxi-rt:${DS_RT_TAG}"
BUILD_DIR="$(dirname "${BASH_SOURCE[0]}")/../images/kxi-rt"
BUILD_ARGS=(--build-arg DS_REGISTRY="$DS_REGISTRY" --build-arg DS_RT_TAG="$DS_RT_TAG")

do_run() {
  docker run --rm -it \
        --name kx-db-rt \
        --memory "${DS_OTHER_MEM_LIMIT:-0}" \
        --network kx-db \
        --hostname rt-data-0 \
        -p "${DS_PORT_BUS:-5002}:5002" \
        -p 16000:6000 \
        -p 6001:6001 \
        -p 4000:4000 \
        -p 4998:4998 \
        -v "$(pwd)/data/rt:/s" \
        -e KDB_LICENSE_B64 \
        -e KDB_K4LICENSE_B64 \
        -e RT_SEQ_SESSION_PATH=/s/session \
        -e RT_SINK=data \
        -e RT_TOPIC_PREFIX=rt- \
        "$1" \
        -p 6000 -in /s/in -out /s/out -cp /s/state -size 1
}
