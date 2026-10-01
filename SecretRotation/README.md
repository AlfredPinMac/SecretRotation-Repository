# 3-Service Secret Rotation Repository

This repository contains automated tools and scripts to coordinate zero-downtime secret rotation across all three architectural layers:

1. **Frontend Layer (NGINX Reverse Proxy)**:
   - Secret: `API_SECRET` (`X-API-Key`).
   - Action: Generates a new cryptographic random key, updates `/secrets/api_secret.env`, regenerates NGINX config template, and issues a graceful `nginx -s reload`.
2. **Backend Layer (Flask API)**:
   - Action: Dynamically consumes the rotated `API_SECRET` and `LDAP_ADMIN_PASSWORD` from the shared volume on each request without requiring container restarts.
   - Crucial Constraint: `DATABASE_ENCRYPTION_KEY` is explicitly maintained and NOT rotated, guaranteeing that previously encrypted SQLite records remain decodable.
3. **LDAP Layer (OpenLDAP Directory)**:
   - Secret: `LDAP_ADMIN_PASSWORD`.
   - Action: Generates a new administrative credential, changes the live password in OpenLDAP using `ldappasswd`, and updates `/secrets/ldap_secret.env`.

## Scripts

- **`rotate-all.sh`**: Performs an immediate, coordinated single-cycle rotation across all 3 services and outputs an audit log.
- **`rotate-frontend.sh`**: Rotates only the NGINX / Backend API key.
- **`rotate-ldap.sh`**: Rotates only the OpenLDAP administrative credential.
- **`rotate-daemon.sh`**: Continuous background engine that executes `rotate-all.sh` every `ROTATION_INTERVAL_SECONDS` (default: 120s / 2 minutes).

## Manual Execution Examples

Run a single rotation cycle:
```bash
docker exec security_rotator /bin/sh /rotation/rotate-all.sh
```

Or execute from the host:
```bash
./rotate-all.sh
```
