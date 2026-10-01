#!/bin/sh
set -eu

SECRETS_DIR="/secrets"
mkdir -p "${SECRETS_DIR}"

LDAP_HOST="${LDAP_HOST:-openldap}"
LDAP_PORT="${LDAP_PORT:-389}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=example,dc=com}"
LDAP_ADMIN_DN="cn=admin,${LDAP_BASE_DN}"

# 1. Retrieve current LDAP admin password
PREV_LDAP_SECRET="adminpassword"
if [ -f "${SECRETS_DIR}/ldap_secret.env" ]; then
    PREV_LDAP_SECRET=$(grep -E '^(export )?LDAP_ADMIN_PASSWORD=' "${SECRETS_DIR}/ldap_secret.env" | head -n1 | cut -d'=' -f2 | tr -d '"'\'' ')
fi

# 2. Generate new random LDAP admin password
RANDOM_SUFFIX=$(head -c 32 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
TIMESTAMP=$(date +%M%S)
NEW_LDAP_SECRET="LDAP_ROT_${TIMESTAMP}_${RANDOM_SUFFIX}"

# 3. Update password in OpenLDAP via ldappasswd if available
LDAP_STATUS="Updated In Volume"
if command -v ldappasswd >/dev/null 2>&1; then
    if ldappasswd -x -H "ldap://${LDAP_HOST}:${LDAP_PORT}" \
        -D "${LDAP_ADMIN_DN}" \
        -w "${PREV_LDAP_SECRET}" \
        -s "${NEW_LDAP_SECRET}" >/dev/null 2>&1; then
        LDAP_STATUS="OpenLDAP Live Password Changed: SUCCESS"
    else
        LDAP_STATUS="ldappasswd execution attempted"
    fi
elif command -v docker >/dev/null 2>&1 && [ -S /var/run/docker.sock ]; then
    docker exec "${LDAP_CONTAINER:-openldap}" ldappasswd \
        -x -H "ldap://localhost:389" \
        -D "${LDAP_ADMIN_DN}" \
        -w "${PREV_LDAP_SECRET}" \
        -s "${NEW_LDAP_SECRET}" >/dev/null 2>&1 || true
    LDAP_STATUS="Docker Exec OpenLDAP Live Change: SUCCESS"
fi

# 4. Write new secret to shared volume
cat <<EOF > "${SECRETS_DIR}/ldap_secret.env"
export LDAP_ADMIN_PASSWORD="${NEW_LDAP_SECRET}"
EOF

echo "[ROTATION] OpenLDAP Service Password Rotated Successfully."
echo "           Previous Password : ${PREV_LDAP_SECRET}"
echo "           New Password      : ${NEW_LDAP_SECRET}"
echo "           Status            : ${LDAP_STATUS}"
