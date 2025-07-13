#!/bin/bash

echo "🔍 Verificando estructura del proyecto..."

BASE_DIR=~/proyecto2-Cloud/backend

echo ""
echo "📁 Directorio base: $BASE_DIR"
if [ -d "$BASE_DIR" ]; then
    echo "✅ Directorio base existe"
    echo ""
    echo "📂 Contenido del directorio backend:"
    ls -la "$BASE_DIR"
else
    echo "❌ Directorio base no existe"
    echo "🔍 Buscando proyecto en directorio actual..."
    find . -name "api-*" -type d 2>/dev/null
fi

echo ""
echo "🔍 Verificando APIs específicas:"

APIs=("api-usuarios" "api-productos" "api-compras")

for api in "${APIs[@]}"; do
    api_path="$BASE_DIR/$api"
    echo -n "  $api: "
    if [ -d "$api_path" ]; then
        echo "✅ Existe en $api_path"
        if [ -f "$api_path/serverless.yml" ]; then
            echo "    ✅ serverless.yml encontrado"
        else
            echo "    ⚠️  serverless.yml no encontrado"
        fi
    else
        echo "❌ No encontrado en $api_path"
        # Buscar en otros lugares
        found=$(find ~/proyecto2-Cloud -name "$api" -type d 2>/dev/null | head -1)
        if [ ! -z "$found" ]; then
            echo "    🔍 Encontrado en: $found"
        fi
    fi
done

echo ""
echo "💡 Si alguna API no se encuentra, verifica las rutas en el script general.sh"
