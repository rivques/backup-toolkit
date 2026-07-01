#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Load configuration
source "$SCRIPT_DIR/.env"

HOSTNAME="$(hostname)"
TIMESTAMP="$(date --iso-8601=seconds)"

BODY=$(
cat <<EOF
timestamp:
$TIMESTAMP

hostname:
$HOSTNAME

hostname -I:
$(hostname -I)

uptime:
$(uptime)

tailscale status:
$(tailscale status 2>&1)
EOF
)

curl \
    --fail \
    --silent \
    --show-error \
    --max-time "${CURL_TIMEOUT:-15}" \
    -X POST \
    --data-binary "$BODY" \
    "$HC_PING_URL"