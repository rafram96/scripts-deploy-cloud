#!/bin/bash
set -e

# Configuración por defecto
STAGE="dev"

# Función de ayuda
usage() {
  echo "Uso: $0 [OPCIONES]"
  echo ""
  echo "OPCIONES:"
  echo "  -s, --stage STAGE    Stage a desplegar (dev, test, prod). Default: dev"
  echo "  -h, --help           Mostrar esta ayuda"
  echo ""
  echo "EJEMPLOS:"
  echo "  $0                   # Desplegar en dev (default)"
  echo "  $0 -s prod           # Desplegar en prod"
  echo "  $0 --stage test      # Desplegar en test"
  exit 1
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--stage)
      STAGE="$2"
      if [[ ! "$STAGE" =~ ^(dev|test|prod)$ ]]; then
        echo "❌ Stage inválido: $STAGE. Debe ser: dev, test, o prod"
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "❌ Opción desconocida: $1"
      usage
      ;;
  esac
done

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR=~/logs
LOG_FILE="$LOG_DIR/api_compras_${STAGE}_$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

API_DIR=~/proyecto2-Cloud/backend/api-compras

echo "🚀 Desplegando api-compras en stage: $STAGE"
echo "📋 Log: $LOG_FILE"
echo ""

if [ ! -d "$API_DIR" ]; then
  echo "❌ api-compras no encontrado en $API_DIR"
  exit 1
fi

cd "$API_DIR"
echo "🗑️ Eliminando api-compras en $STAGE..." | tee -a "$LOG_FILE"
sls remove --stage "$STAGE" >> "$LOG_FILE" 2>&1 || echo "⚠️ Fallo al eliminar api-compras en $STAGE (posiblemente ya no existe)" | tee -a "$LOG_FILE"

echo "🚀 Desplegando api-compras en $STAGE..." | tee -a "$LOG_FILE"
DEPLOY_OUTPUT=$(mktemp)

if sls deploy --stage "$STAGE" > "$DEPLOY_OUTPUT" 2>&1; then
  cat "$DEPLOY_OUTPUT" >> "$LOG_FILE"
  echo "✅ api-compras desplegado correctamente en $STAGE" | tee -a "$LOG_FILE"
  echo "📋 Log guardado en: $LOG_FILE"
  echo -e "\n🌐 Endpoints de api-compras en $STAGE:"
  grep -E "https://.*\.amazonaws\.com" "$DEPLOY_OUTPUT" | sort -u
  rm -f "$DEPLOY_OUTPUT"
else
  cat "$DEPLOY_OUTPUT" >> "$LOG_FILE"
  echo "❌ Fallo al desplegar api-compras en $STAGE, revisa el log $LOG_FILE" | tee -a "$LOG_FILE"
  rm -f "$DEPLOY_OUTPUT"
  exit 1
fi