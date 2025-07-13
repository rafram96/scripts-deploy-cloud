#!/bin/bash
set -e

REPO_URL="https://github.com/rafram96/proyecto2-Cloud.git"
CLONE_DIR="$HOME/proyecto2-Cloud"

echo "🔁 Eliminando directorio existente ($CLONE_DIR)..."
rm -rf "$CLONE_DIR"

echo "🌐 Clonando repositorio desde $REPO_URL..."
if git clone "$REPO_URL" "$CLONE_DIR"; then
  echo "✅ Repositorio clonado exitosamente en $CLONE_DIR"
else
  echo "❌ Error al clonar el repositorio"
  exit 1
fi
