#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASE_IMAGE=${BASE_IMAGE:-ciwei123321/foam-api-v2:latest}
UNLOCKED_IMAGE=${UNLOCKED_IMAGE:-foam-api-v2-local-unlocked:local}
PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
COMPOSE_FILE=${COMPOSE_FILE:-$PROJECT_DIR/docker-compose.yml}
API_SERVICE=${API_SERVICE:-foam-api-v2}
START_COMPOSE=0

usage() {
    printf '%s\n' \
        'Usage: ./unlock-docker.sh [options]' \
        '  --start                  Build the image and recreate the API service' \
        '  --project-dir DIR       Compose project directory (default: current directory)' \
        '  --compose-file FILE     Compose file (default: PROJECT_DIR/docker-compose.yml)' \
        '  --service NAME          API service name (default: foam-api-v2)' \
        '  --base-image IMAGE      Official API image to patch' \
        '  --image IMAGE           Name for the local unlocked image'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --start)
            START_COMPOSE=1
            ;;
        --project-dir)
            PROJECT_DIR=$2
            shift
            ;;
        --compose-file)
            COMPOSE_FILE=$2
            shift
            ;;
        --service)
            API_SERVICE=$2
            shift
            ;;
        --base-image)
            BASE_IMAGE=$2
            shift
            ;;
        --image)
            UNLOCKED_IMAGE=$2
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if ! command -v docker >/dev/null 2>&1; then
    printf '%s\n' 'Docker CLI was not found.' >&2
    exit 1
fi

printf 'Building local unlocked image: %s\n' "$UNLOCKED_IMAGE"
docker build \
    --build-arg "BASE_IMAGE=$BASE_IMAGE" \
    --tag "$UNLOCKED_IMAGE" \
    --file "$SCRIPT_DIR/Dockerfile" \
    "$SCRIPT_DIR"

printf 'Built: %s\n' "$UNLOCKED_IMAGE"

if [ "$START_COMPOSE" -eq 1 ]; then
    if [ ! -f "$COMPOSE_FILE" ]; then
        printf 'Compose file not found: %s\n' "$COMPOSE_FILE" >&2
        exit 1
    fi

    override_file=$(mktemp "${TMPDIR:-/tmp}/foam-local-unlocked-compose.XXXXXX.yml")
    cleanup() {
        rm -f "$override_file"
    }
    trap cleanup EXIT INT TERM

    printf 'services:\n  %s:\n    image: %s\n    pull_policy: never\n' "$API_SERVICE" "$UNLOCKED_IMAGE" > "$override_file"
    docker compose \
        --project-directory "$PROJECT_DIR" \
        -f "$COMPOSE_FILE" \
        -f "$override_file" \
        up -d --force-recreate "$API_SERVICE"
    printf 'API service recreated with the local unlocked image.\n'
fi
