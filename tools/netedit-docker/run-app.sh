#!/bin/sh
# Launch netedit or sumo-gui in the netedit-novnc container and print the link to open.
# Usage: run-app.sh netedit|sumo-gui [program arguments...]
# With no arguments the app starts without a file (use File -> Open; Network/ is mounted at /work).
# Environment: PORT (host port, default 6080), IMAGE (default netedit-novnc).
set -eu

APP=${1:?usage: run-app.sh netedit|sumo-gui [arguments...]}
shift
case "$APP" in
  netedit)  NAME=netedit ;;
  sumo-gui) NAME=sumo-gui ;;
  *) echo "Unknown app '$APP' (expected netedit or sumo-gui)" >&2; exit 2 ;;
esac
ARGS="$*"  # empty: the app opens without a file; Network/ is still mounted at /work

IMAGE=${IMAGE:-netedit-novnc}
PORT=${PORT:-6080}
DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$DIR/../.." && pwd)
URL="http://localhost:$PORT/vnc.html"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Install Docker Desktop first." >&2; exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop and try again." >&2; exit 1
fi

# Ask whether to remove a container; return 1 if the user declines.
confirm_kill() { # $1 = container name, $2 = reason
  printf "%s Kill it? [y/N] " "$2"
  read -r answer || answer=n
  case "$answer" in
    y|Y|yes|YES) docker rm -f "$1" >/dev/null; echo "Removed container '$1'." ;;
    *) return 1 ;;
  esac
}

# 1. A container with our name (running or stopped) would block `docker run --name`.
if [ -n "$(docker ps -aq --filter "name=^${NAME}$")" ]; then
  if [ -n "$(docker ps -q --filter "name=^${NAME}$")" ]; then
    reason="Container '$NAME' is already running."
  else
    reason="A stopped container '$NAME' exists."
  fi
  if ! confirm_kill "$NAME" "$reason"; then
    [ -n "$(docker ps -q --filter "name=^${NAME}$")" ] && echo "Keeping it. Open: $URL"
    exit 0
  fi
fi

# 2. Another container (e.g. the other app) may already hold the host port.
OTHER=$(docker ps --filter "publish=$PORT" --format '{{.Names}}' | head -n 1)
if [ -n "$OTHER" ]; then
  if ! confirm_kill "$OTHER" "Container '$OTHER' is using port $PORT."; then
    echo "Port $PORT is busy. Re-run with another port, e.g. PORT=6081 $0 $APP" >&2
    exit 1
  fi
fi

# 3. Build the image. start.sh is baked into it, so always run the build: it is
# cached (near-instant) when nothing changed, and picks up edits when it did.
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -q -t "$IMAGE" "$DIR" >/dev/null
else
  echo "Image '$IMAGE' not found; building it (this takes a few minutes)..."
  docker build -t "$IMAGE" "$DIR"
fi

# 4. Start the container ($ARGS is deliberately word-split).
echo "Starting $APP${ARGS:+ ($ARGS)}..."
# shellcheck disable=SC2086
docker run -d --name "$NAME" -p "127.0.0.1:$PORT:6080" -e "APP=$APP" \
  -v "$ROOT/Network:/work" "$IMAGE" /start.sh $ARGS >/dev/null

# 5. Wait until the noVNC page answers (or the container dies).
i=0
until curl -fs -o /dev/null "$URL" 2>/dev/null; do
  i=$((i + 1))
  if [ -z "$(docker ps -q --filter "name=^${NAME}$")" ]; then
    echo "Container '$NAME' exited unexpectedly. Logs:" >&2
    docker logs "$NAME" >&2 || true
    exit 1
  fi
  if [ "$i" -ge 60 ]; then
    echo "Timed out waiting for $URL; check 'docker logs $NAME'." >&2; exit 1
  fi
  sleep 0.5
done

echo
echo "$APP is up. Open this link and click Connect:"
echo "  $URL"
echo
echo "Stop it with: docker rm -f $NAME"
