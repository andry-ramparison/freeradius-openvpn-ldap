#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONTAINER="p16-ldap"
ACL_DIR="openldap/acl"
MARKER='cn=radius-reader,dc=esti,dc=lab'

echo "Attente de $CONTAINER (healthy)..."
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)" = "healthy" ]; do
  sleep 2
done

# Les lignes LDIF longues sont repliées : on les recolle avant de chercher.
current_acl() {
  docker exec "$CONTAINER" ldapsearch -Y EXTERNAL -H ldapi:/// \
    -b "olcDatabase={1}mdb,cn=config" olcAccess 2>/dev/null | tr -d '\n '
}

if current_acl | grep -q "$MARKER"; then
  echo "ACL radius-reader deja presente : rien a appliquer."
else
  for f in "$ACL_DIR"/*.ldif; do
    echo "Application de $f"
    docker cp "$f" "$CONTAINER:/tmp/$(basename "$f")"
    docker exec "$CONTAINER" ldapmodify -Y EXTERNAL -H ldapi:/// -f "/tmp/$(basename "$f")"
  done
fi

echo "Redemarrage de FreeRADIUS..."
docker compose restart freeradius

echo "Termine. Verification : docker compose logs freeradius | tail -5"