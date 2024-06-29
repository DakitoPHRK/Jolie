#!/bin/bash

# Verifica si se proporcionó una IP como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <nueva_ip>"
  exit 1
fi

NUEVA_IP=$1
ARCHIVO_CONFIG="/root/lancache/.env"

# Verifica si el archivo de configuración existe
if [ ! -f "$ARCHIVO_CONFIG" ]; then
  echo "El archivo de configuración no existe: $ARCHIVO_CONFIG"
  exit 1
fi

# Usa sed para actualizar las líneas LANCACHE_IP y DNS_BIND_IP
sed -i "s/^LANCACHE_IP=.*/LANCACHE_IP=$NUEVA_IP/" "$ARCHIVO_CONFIG"
sed -i "s/^DNS_BIND_IP=.*/DNS_BIND_IP=$NUEVA_IP/" "$ARCHIVO_CONFIG"

echo "Archivo de configuración actualizado con la IP: $NUEVA_IP"
