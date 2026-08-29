#!/bin/sh
# Turnkey JWT_SECRET for LAN Games: if the operator didn't supply one,
# generate a secret on first boot and persist it in the data volume so
# login tokens survive container restarts and image updates.
set -e

if [ -z "$JWT_SECRET" ]; then
  secret_file="${JWT_SECRET_FILE:-/app/server/data/.jwt_secret}"
  if [ ! -f "$secret_file" ]; then
    node -e "process.stdout.write(require('crypto').randomBytes(48).toString('hex'))" > "$secret_file"
    chmod 600 "$secret_file"
    echo "[entrypoint] Generated new JWT secret at $secret_file"
  fi
  JWT_SECRET="$(cat "$secret_file")"
  export JWT_SECRET
  echo "[entrypoint] Using persisted JWT secret from $secret_file"
fi

exec "$@"
