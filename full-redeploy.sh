#!/bin/bash
set -e

# === PARÁMETROS ===
CLONE=false
STAGE="dev"  # default

# === PARSEO DE ARGUMENTOS ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--stage)
      STAGE="$2"
      if [[ ! "$STAGE" =~ ^(dev|test|prod)$ ]]; then
        echo "❌ Stage inválido: $STAGE. Usa dev, test o prod"
        exit 1
      fi
      shift 2
      ;;
    --clone)
      CLONE=true
      shift
      ;;
    -h|--help)
      echo "Uso: $0 [--clone] [-s dev|test|prod]"
      echo ""
      echo "Opciones:"
      echo "  --clone          Clonar el repositorio antes de desplegar"
      echo "  -s, --stage      Stage a usar (dev, test, prod). Default: dev"
      exit 0
      ;;
    *)
      echo "❌ Opción desconocida: $1"
      exit 1
      ;;
  esac
done

# === CONFIG ===
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR=~/logs
MASTER_LOG="$LOG_DIR/full_redeploy_${STAGE}_$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

echo "📦 Iniciando redeploy completo [$STAGE] ($TIMESTAMP)..." | tee -a "$MASTER_LOG"

# === 1. Clonar repositorio (si se pasa --clone)
if [ "$CLONE" = true ]; then
  echo "📥 Clonando repositorio..." | tee -a "$MASTER_LOG"
  ~/scripts-deploy-cloud/clone.sh >> "$MASTER_LOG" 2>&1
else
  echo "⏭️  Clonado omitido (sin --clone)" | tee -a "$MASTER_LOG"
fi

# === 2. Desplegar APIs
~/scripts-deploy-cloud/deploy-usuarios.sh -s "$STAGE"
~/scripts-deploy-cloud/deploy-productos.sh -s "$STAGE"
~/scripts-deploy-cloud /deploy-compras.sh -s "$STAGE"

# === 3. Mostrar endpoints
echo -e "\n🌐 Endpoints desplegados en $STAGE:" | tee -a "$MASTER_LOG"
grep -hE "https://.*\.amazonaws\.com" "$LOG_DIR"/api_*_"$STAGE"_*.log | sort -u | tee -a "$MASTER_LOG"

echo -e "\n✅ Redeploy completo en stage '$STAGE' finalizado exitosamente"
echo "📄 Log maestro guardado en: $MASTER_LOG"
