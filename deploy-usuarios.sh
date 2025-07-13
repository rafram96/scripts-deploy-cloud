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
LOG_FILE="$LOG_DIR/api_usuarios_${STAGE}_$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

API_DIR=~/proyecto2-Cloud/backend/api-usuarios

echo "🚀 Desplegando api-usuarios en stage: $STAGE"
echo "📋 Log: $LOG_FILE"
echo ""

if [ ! -d "$API_DIR" ]; then
  echo "❌ api-usuarios no encontrado en $API_DIR"
  exit 1
fi

cd "$API_DIR"

echo "🗑️ Eliminando api-usuarios en $STAGE..."
sls remove --stage "$STAGE" > "$LOG_FILE" 2>&1 || echo "⚠️ Fallo al eliminar api-usuarios en $STAGE (posiblemente ya no existe)"

echo "🚀 Desplegando api-usuarios en $STAGE..."
if sls deploy --stage "$STAGE" >> "$LOG_FILE" 2>&1; then
  echo "✅ api-usuarios desplegado correctamente en $STAGE"
  echo "📋 Log guardado en: $LOG_FILE"
  
  echo -e "\n🌐 Endpoints desplegados en $STAGE:"
  # Buscar exactamente los 3 endpoints que se acaban de crear
  grep -E "POST.*auth/registro|POST.*auth/login|GET.*auth/validar" "$LOG_FILE" | sed 's/^[ \t]*//'
  
else
  echo "❌ Fallo al desplegar api-usuarios en $STAGE"
  echo "📖 Log de errores:"
  echo "----------------------------------------"
  cat "$LOG_FILE"
  echo "----------------------------------------"
  exit 1
fi
