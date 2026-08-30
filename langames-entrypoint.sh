#!/bin/sh
# Turnkey startup for LAN Games on Unraid.
#
# Runs as root just long enough to (1) make the data volume writable —
# Unraid creates host appdata dirs owned by root, which the upstream
# image's non-root user can't write to — and (2) generate and persist
# JWT_SECRET when the operator didn't supply one. Then drops privileges
# to PUID:PGID (Unraid-standard 99:100 by default) and execs the app.
set -e

PUID="${PUID:-99}"
PGID="${PGID:-100}"
DATA_DIR="${DATA_DIR:-/app/server/data}"

mkdir -p "$DATA_DIR"
chown -R "$PUID:$PGID" "$DATA_DIR"

if [ -z "$JWT_SECRET" ]; then
  secret_file="${JWT_SECRET_FILE:-$DATA_DIR/.jwt_secret}"
  if [ ! -f "$secret_file" ]; then
    node -e "process.stdout.write(require('crypto').randomBytes(48).toString('hex'))" > "$secret_file"
    echo "[entrypoint] Generated new JWT secret at $secret_file"
  fi
  chown "$PUID:$PGID" "$secret_file"
  chmod 600 "$secret_file"
  JWT_SECRET="$(cat "$secret_file")"
  export JWT_SECRET
  echo "[entrypoint] Using persisted JWT secret from $secret_file"
fi

echo "[entrypoint] Dropping privileges to $PUID:$PGID"
exec setpriv --reuid "$PUID" --regid "$PGID" --clear-groups "$@"
