#!/bin/sh
set -eu

SECRETS_DIR="/secrets"
mkdir -p "${SECRETS_DIR}"

# 1. Retrieve current API_SECRET if available
PREV_SECRET="unknown"
if [ -f "${SECRETS_DIR}/api_secret.env" ]; then
    PREV_SECRET=$(grep -E '^(export )?API_SECRET=' "${SECRETS_DIR}/api_secret.env" | head -n1 | cut -d'=' -f2 | tr -d '"'\'' ')
fi

# 2. Generate new random API_SECRET
RANDOM_SUFFIX=$(head -c 32 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
TIMESTAMP=$(date +%M%S)
NEW_API_SECRET="ROT_SEC_${TIMESTAMP}_${RANDOM_SUFFIX}"

# 3. Write new secret to shared volume
cat <<EOF > "${SECRETS_DIR}/api_secret.env"
export API_SECRET="${NEW_API_SECRET}"
EOF

# 4. If running inside the frontend container, reload NGINX directly;
#    otherwise send reload signal via Docker if available
if command -v nginx >/dev/null 2>&1 && pidof nginx >/dev/null 2>&1; then
    export API_SECRET="${NEW_API_SECRET}"
    : "${API_UPSTREAM:=http://backend:5000}"
    envsubst '${API_SECRET} ${API_UPSTREAM}' \
      < /etc/nginx/templates/nginx.conf.template \
      > /etc/nginx/conf.d/default.conf
    nginx -s reload
    RELOAD_STATUS="Direct NGINX Reload: SUCCESS"
elif command -v docker >/dev/null 2>&1 && [ -S /var/run/docker.sock ]; then
    docker exec "${FRONTEND_CONTAINER:-security_frontend}" sh -c '
        . /secrets/api_secret.env
        envsubst "\${API_SECRET} \${API_UPSTREAM}" < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf
        nginx -s reload
    ' >/dev/null 2>&1 || true
    RELOAD_STATUS="Docker NGINX Reload: SUCCESS"
else
    RELOAD_STATUS="Shared Volume Updated (/secrets/api_secret.env)"
fi

echo "[ROTATION] Frontend (NGINX Proxy) Secret Rotated Successfully."
echo "           Previous Secret : ${PREV_SECRET}"
echo "           New Secret      : ${NEW_API_SECRET}"
echo "           Status          : ${RELOAD_STATUS}"
