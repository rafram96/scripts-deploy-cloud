#!/bin/bash
set -e

# ====================
# FUNCIÓN DE AYUDA
# ====================
usage() {
    echo "Uso: $0 [-s stage]"
    echo "  -s, --stage    Stage a usar (dev | test | prod). Default: dev"
    echo "  -h, --help     Muestra esta ayuda"
    exit 1
}

# ====================
# PARSE DE ARGUMENTOS
# ====================
STAGE="dev"  # valor por defecto

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--stage)
      STAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "❌ Argumento desconocido: $1"
      usage
      ;;
  esac
done

# Validar stage
if [[ ! "$STAGE" =~ ^(dev|test|prod)$ ]]; then
  echo "❌ Stage inválido: $STAGE. Usa: dev, test o prod"
  exit 1
fi

# ====================
# CONFIGURACIÓN
# ====================
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR=~/logs
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/api_productos_${STAGE}_$TIMESTAMP.log"
API_DIR=~/proyecto2-Cloud/backend/api-productos
LAYER_DIR="$API_DIR/layers/dependencies/nodejs"

# ====================
# INICIO DEL SCRIPT
# ====================
echo "🚀 Desplegando api-productos en stage: $STAGE" | tee -a "$LOG_FILE"

# Validar directorio
if [ ! -d "$API_DIR" ]; then
  echo "❌ api-productos no encontrado en $API_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

cd "$API_DIR"

# ====================
# ELIMINAR STACK EXISTENTE
# ====================
echo "🗑️ Eliminando stack anterior..." | tee -a "$LOG_FILE"
sls remove --stage "$STAGE" >> "$LOG_FILE" 2>&1 || echo "⚠️ Fallo al eliminar (posiblemente ya estaba limpio)" | tee -a "$LOG_FILE"

# ====================
# VERIFICAR/INSTALAR LAYER
# ====================
if [ -d "$LAYER_DIR" ]; then
  echo "📦 Verificando dependencias del layer..." | tee -a "$LOG_FILE"
  cd "$LAYER_DIR"

  if [ ! -d "node_modules/jsonwebtoken" ]; then
    echo "⚠️ jsonwebtoken no encontrado. Reinstalando dependencias..." | tee -a "$LOG_FILE"
    rm -rf node_modules package-lock.json
    npm install --production >> "$LOG_FILE" 2>&1
  fi

  if [ -d "node_modules/jsonwebtoken" ]; then
    echo "✅ jsonwebtoken correctamente instalado" | tee -a "$LOG_FILE"
  else
    echo "❌ No se pudo instalar jsonwebtoken" | tee -a "$LOG_FILE"
    exit 1
  fi
  cd "$API_DIR"
else
  echo "⚠️ Directorio de layer no encontrado: $LAYER_DIR" | tee -a "$LOG_FILE"
fi

# ====================
# DEPLOY NUEVO
# ====================
echo "🚀 Realizando nuevo deploy..." | tee -a "$LOG_FILE"
DEPLOY_OUTPUT=$(mktemp)

if sls deploy --stage "$STAGE" > "$DEPLOY_OUTPUT" 2>&1; then
  cat "$DEPLOY_OUTPUT" >> "$LOG_FILE"
  echo "✅ Deploy exitoso para api-productos ($STAGE)" | tee -a "$LOG_FILE"
  echo "📋 Log: $LOG_FILE"
  echo -e "\n🌐 Endpoints desplegados:"
  grep -E "https://.*\.amazonaws\.com" "$DEPLOY_OUTPUT" | sort -u
  rm -f "$DEPLOY_OUTPUT"
else
  cat "$DEPLOY_OUTPUT" >> "$LOG_FILE"
  echo "❌ Fallo en el deploy. Ver log: $LOG_FILE" | tee -a "$LOG_FILE"
  rm -f "$DEPLOY_OUTPUT"
  exit 1
fi
