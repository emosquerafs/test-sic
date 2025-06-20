#!/bin/sh

# Instalar curl (requerido en Alpine)
apk add --no-cache curl >/dev/null

echo "Esperando que Vault esté disponible en http://vault:8200..."
while ! curl -s http://vault:8200/v1/sys/health >/dev/null; do
  sleep 1
done

echo "Vault está disponible. Habilitando kv secrets engine en /kv ..."

VAULT_ADDR=http://vault:8200
VAULT_TOKEN=root

# Habilitar el secrets engine en /kv si no está
curl --silent --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{"type": "kv", "options": {"version": "2"}}' \
     "$VAULT_ADDR/v1/sys/mounts/kv"

echo "Escribiendo secreto en kv/applications/local/TestSic ..."

# Escribir el secreto con la estructura esperada (kv v2 usa /data/)
curl --silent --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data @- \
     "$VAULT_ADDR/v1/kv/data/applications/local/TestSic" <<EOF
{
  "data": {
    "jwt.auth.converter.principalAttribute": "preferred_username",
    "jwt.auth.converter.resourceId": "SicTest",
    "spring.datasource.hikari.connection-timeout": "30000",
    "spring.datasource.hikari.idle-timeout": "30000",
    "spring.datasource.hikari.max-lifetime": "2000000",
    "spring.datasource.hikari.maximum-pool-size": "20",
    "spring.datasource.hikari.minimum-idle": "5",
    "spring.datasource.hikari.pool-name": "SicDB",
    "spring.datasource.hikari.register-mbeans": "true",
    "spring.datasource.password": "123456",
    "spring.datasource.url": "jdbc:postgresql://localhost:5432/sic?currentSchema=public&useSSL=false&serverTimezone=America/Bogota",
    "spring.datasource.username": "sicdbadmin",
    "spring.security.oauth2.resourceserver.jwt.issuer-uri": "http://localhost:8080/realms/SicTest"
  }
}
EOF


echo "✅ Secretos escritos correctamente en Vault bajo 'kv/applications/local/TestSic'"
