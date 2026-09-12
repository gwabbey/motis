#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
rm -f osm.log

OSM_URL="https://download.geofabrik.de/europe/italy-latest.osm.pbf"
OSM_FILE="./italy.osm.pbf"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a osm.log
}

log "downloading italy.osm.pbf from geofabrik..."
if wget -O "${OSM_FILE}.tmp" "$OSM_URL" >> osm.log 2>&1; then
    mv "${OSM_FILE}.tmp" "$OSM_FILE"
    log "OSM download completed successfully"
else
    log "ERROR: OSM download failed"
    rm -f "${OSM_FILE}.tmp"
    exit 1
fi

log "running MOTIS import..."
if ! docker compose run --rm -T motis /app/motis import >> .log 2>&1; then
    log "ERROR: MOTIS import failed. Aborting."
    exit 1
fi
log "MOTIS import completed successfully"

log "restarting MOTIS server with updated graph..."
if ! docker compose restart motis >> .log 2>&1; then
    log "ERROR: MOTIS server failed to restart"
    exit 1
fi
log "MOTIS server restarted successfully"