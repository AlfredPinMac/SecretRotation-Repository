#!/bin/sh
set -eu

INTERVAL="${ROTATION_INTERVAL_SECONDS:-120}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "================================================================================"
echo "[SECRET ROTATION DAEMON] Starting Automated Rotation Engine"
echo "Rotation Interval : ${INTERVAL} seconds (2 minutes)"
echo "Services Managed  : 1. Frontend (NGINX), 2. Backend (Flask), 3. LDAP (OpenLDAP)"
echo "Database Key      : Fixed (AES-256 Fernet) - WILL NOT BE ROTATED"
echo "================================================================================"

# Initial wait or immediate rotation
while true; do
    echo "[DAEMON] Next rotation in ${INTERVAL} seconds..."
    sleep "${INTERVAL}"
    /bin/sh "${SCRIPT_DIR}/rotate-all.sh" || echo "[DAEMON WARNING] Rotation cycle encountered an error"
done
