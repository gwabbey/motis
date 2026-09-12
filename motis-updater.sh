#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
rm -f .log

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a .log
}

if [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
fi

log "downloading GTFS files..."
if ! bash ./download-gtfs.sh gtfs.json . >> .log 2>&1; then
    log "ERROR: GTFS download failed"
    exit 1
fi
log "GTFS download completed successfully"

log "running MOTIS import..."
if ! docker compose run --rm -T motis /app/motis import >> .log 2>&1; then
    log "ERROR: MOTIS import failed. Aborting."
    exit 1
fi
log "MOTIS import completed successfully"

log "restarting MOTIS server with updated data..."
if ! docker compose restart motis >> .log 2>&1; then
    log "ERROR: MOTIS server failed to restart"
    exit 1
fi
log "MOTIS server restarted successfully"