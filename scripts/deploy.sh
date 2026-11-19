#!/usr/bin/env bash
set -euo pipefail

SERVICE=$1     # 'api' o 'frontend'
NEW_TAG=$2     # commit SHA desde GitHub Actions

if [ -z "${SERVICE:-}" ] || [ -z "${NEW_TAG:-}" ]; then
  echo "Uso: ./scripts/deploy.sh <api|frontend> <nuevo_tag>"
  exit 1
fi

if [ ! -f .env ]; then
  echo "No se encontró .env en el servidor. Copia .env.example y complétalo."
  exit 1
fi

if [ ! -f env/api.env ]; then
  echo "No se encontró env/api.env. Copia env/api.env.example y complétalo."
  exit 1
fi

# shellcheck disable=SC1091
source .env

mkdir -p data/estatico/imagenes postgres-prod/data
# UID 1000 = usuario `node` de la imagen api (subidas a /app/estatico)
chown -R 1000:1000 data/estatico 2>/dev/null || chmod -R u+rwX,g+rwX data/estatico

if [ "$SERVICE" = "api" ]; then
  VAR_NAME="API_TAG"
  SERVICE_NAME="api-cine-prod"
  OLD_TAG="${API_TAG:-}"
elif [ "$SERVICE" = "frontend" ]; then
  VAR_NAME="FRONTEND_TAG"
  SERVICE_NAME="frontend-cine-prod"
  OLD_TAG="${FRONTEND_TAG:-}"
else
  echo "Servicio no válido: $SERVICE. Usa 'api' o 'frontend'."
  exit 1
fi

echo "Desplegando $SERVICE | $OLD_TAG -> $NEW_TAG"

echo "$OLD_TAG" > ".last_${SERVICE}_tag"
sed -i "s/^${VAR_NAME}=.*/${VAR_NAME}=${NEW_TAG}/" .env

docker compose pull "$SERVICE_NAME"
docker compose up -d --no-deps --force-recreate "$SERVICE_NAME"

# Si cambia la API o el frontend, nginx sigue; reiniciar gateway refresca upstreams/DNS
docker compose up -d --no-deps nginx-cine-prod

echo "Verificando salud de $SERVICE_NAME..."
for _ in $(seq 1 18); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$SERVICE_NAME" 2>/dev/null || echo "starting")
  if [ "$STATUS" = "healthy" ]; then
    echo "Despliegue exitoso: $SERVICE_NAME ($NEW_TAG) está healthy."
    exit 0
  fi
  sleep 5
done

echo "Healthcheck falló (estado: $STATUS). Rollback a $OLD_TAG..."
sed -i "s/^${VAR_NAME}=.*/${VAR_NAME}=${OLD_TAG}/" .env
docker compose up -d --no-deps --force-recreate "$SERVICE_NAME"
docker compose up -d --no-deps nginx-cine-prod
echo "Rollback completado a $OLD_TAG."
exit 1
