#!/bin/sh

KEYCLOAK_HOST=http://keycloak:8080
REALM_NAME=SicTest
CLIENT_ID=SicTest
USER_USERNAME=sic
USER_PASSWORD=12345

echo "Esperando que Keycloak esté disponible en $KEYCLOAK_HOST/realms/master..."
until curl -s -f "$KEYCLOAK_HOST/realms/master" >/dev/null; do
  echo "Aún no disponible, esperando..."
  sleep 3
done
echo "Keycloak está disponible."

echo "Obteniendo token de administrador..."
export TOKEN=$(curl -s -X POST "$KEYCLOAK_HOST/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin123" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r .access_token)

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Error obteniendo token de administrador"
  exit 1
fi

# Crear Realm si no existe
echo "Verificando si el realm '$REALM_NAME' existe..."
if curl -s -H "Authorization: Bearer $TOKEN" "$KEYCLOAK_HOST/admin/realms/$REALM_NAME" | grep -q '"realm"'; then
  echo "El realm '$REALM_NAME' ya existe."
else
  echo "Creando realm '$REALM_NAME'..."
  curl -s -X POST "$KEYCLOAK_HOST/admin/realms" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"realm\": \"$REALM_NAME\", \"enabled\": true}"
fi

# Crear cliente si no existe
echo "Verificando si el cliente '$CLIENT_ID' existe..."
CLIENT_EXISTS=$(curl -s -H "Authorization: Bearer $TOKEN" "$KEYCLOAK_HOST/admin/realms/$REALM_NAME/clients" | jq -r ".[] | select(.clientId==\"$CLIENT_ID\") | .id")

if [ -n "$CLIENT_EXISTS" ]; then
  echo "El cliente '$CLIENT_ID' ya existe."
else
  echo "Creando cliente '$CLIENT_ID'..."
  curl -s -X POST "$KEYCLOAK_HOST/admin/realms/$REALM_NAME/clients" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
          "clientId": "'"$CLIENT_ID"'",
          "enabled": true,
          "publicClient": true,
          "redirectUris": ["*"],
          "protocol": "openid-connect"
        }'
fi

# Crear usuario si no existe
echo "Verificando si el usuario '$USER_USERNAME' existe..."
USER_EXISTS=$(curl -s -H "Authorization: Bearer $TOKEN" "$KEYCLOAK_HOST/admin/realms/$REALM_NAME/users?username=$USER_USERNAME" | jq -r ".[0].id")

if [ -n "$USER_EXISTS" ] && [ "$USER_EXISTS" != "null" ]; then
  echo "El usuario '$USER_USERNAME' ya existe."
else
  echo "Creando usuario '$USER_USERNAME'..."
  curl -s -X POST "$KEYCLOAK_HOST/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
          "username": "'"$USER_USERNAME"'",
          "emailVerified": true,
          "email": "'"sic@sic.com"'",
          "firstName": "'"SIC"'",
          "lastName": "'"User"'",          
          "enabled": true,
          "credentials": [
            {
              "type": "password",
              "value": "'"$USER_PASSWORD"'",
              "temporary": false
            }
          ]
        }'
fi

echo "✅ Realm, cliente y usuario de Keycloak asegurados correctamente."
