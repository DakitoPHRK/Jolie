#!/bin/bash

TOKEN="7356269571:AAGT1Lr_vxd7r_klmK0nwllEvqYaYQj9ExM"
URL="https://api.telegram.org/bot$TOKEN"
LOGFILE="recarga.log"
ADMIN_CHAT_ID="297510984"  # ID del administrador
FOTO="foto.jpg"            # Nombre de la foto
declare -A user_photo_count # Contador de fotos enviadas por usuario
declare -A user_first_interaction # Registro de primera interacción del día
declare -A user_authorized # Registro de usuarios autorizados
declare -A user_state
declare -A user_productId
declare -A user_message
declare -A pending_authorizations # Almacena las autorizaciones pendientes

# Cabeceras comunes para todas las solicitudes
CABECERAS=(
    "-H" "Host: apix.movistar.cl"
    "-H" "Content-Type: application/json"
    "-H" "Accept-Encoding: gzip, deflate, br"
    "-H" "User-Agent: Mozilla/5.0 (iPhone; CPU OS 15_2 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/15.2 Mobile/10A5355d Safari/8536.25"
    "-H" "Authorization: Basic NTNjMDgxZWYtYWI0Yi00N2IwLTk1YjQtODkyYjJhYzdkNWYwOjc0ZmMxZjA0LTA2NmItNGQ1My1hM2IwLWUxYzUyMzA2YjU0NQ=="
    "-H" "Accept-Language: es-419,es;q=0.9,es-ES;q=0.8,en;q=0.7,en-GB;q=0.6,en-US;q=0.5"
    "-H" "Accept: application/json, text/plain, */*"
    "-H" "Cookie: NSC_mcwt_Dpoubeps_ijut_ndttxfc=...; _gcl_au=1.1.708563813.1634113342"
    "-H" "Connection: close"
)

# Función para registrar mensajes en el log
log_msg() {
    echo "$(date '+%d-%m-%Y %H:%M:%S') - $1" >> "$LOGFILE"
}

# Función para enviar mensajes a un usuario de Telegram
enviar_mensaje() {
    local chat_id=$1
    local mensaje=$2
    curl -s -X POST "$URL/sendMessage" -d chat_id="$chat_id" -d text="$mensaje" > /dev/null
    log_msg "Mensaje enviado a ${chat_id}: ${mensaje}"
}

# Función para enviar una foto a un usuario de Telegram
enviar_foto() {
    local chat_id=$1
    local foto=$2
    curl -s -X POST "$URL/sendPhoto" -F chat_id="$chat_id" -F photo="@$foto" > /dev/null
    log_msg "Foto enviada a ${chat_id}"
}

# Función para mostrar el menú de bienvenida
mostrar_menu() {
    local chat_id=$1
    local mensaje="¡Bienvenido! Selecciona una opción:
1. GB Libres x 10D 2300
2. Ilim x 10D 2750
3. GB Libres x 3D 1300
4. Ilim x 12D 3050
5. Consulta de saldo
0. Salir"

    # Verificar si ya se envió la foto 2 veces hoy
    if [[ ${user_photo_count[$chat_id]} -lt 2 ]]; then
        enviar_foto "$chat_id" "$FOTO"
        user_photo_count[$chat_id]=$((user_photo_count[$chat_id] + 1))
    fi

    enviar_mensaje "$chat_id" "$mensaje"
    log_msg "Mostrado menú de bienvenida a ${chat_id}"
}

# Función para notificar al administrador sobre un nuevo usuario
notificar_admin() {
    local chat_id=$1
    local username=$2
    local first_name=$3
    local last_name=$4

    local mensaje_admin="⚠️ Nuevo usuario interactuando:
- ID: $chat_id
- Username: $username
- Nombre: $first_name $last_name
¿Deseas autorizar su uso? Responde 'sí' o 'no'."

    enviar_mensaje "$ADMIN_CHAT_ID" "$mensaje_admin"
    log_msg "Notificación enviada al administrador sobre el usuario ${chat_id}"
    pending_authorizations[$ADMIN_CHAT_ID]=$chat_id
}

# Función para procesar la respuesta del administrador
procesar_respuesta_admin() {
    local chat_id=$1
    local respuesta=$2
    local user_to_authorize=${pending_authorizations[$chat_id]}

    if [[ "$respuesta" == "sí" ]]; then
        user_authorized[$user_to_authorize]=1
        enviar_mensaje "$user_to_authorize" "✅ Tu acceso ha sido autorizado por el administrador. ¡Bienvenido!"
        log_msg "Usuario ${user_to_authorize} autorizado por el administrador"
        # Mostrar el menú de bienvenida después de la autorización
        mostrar_menu "$user_to_authorize"
    else
        user_authorized[$user_to_authorize]=0
        enviar_mensaje "$user_to_authorize" "❌ Tu acceso no fue autorizado por el administrador. Contacta a @DakitoLies para más información."
        log_msg "Usuario ${user_to_authorize} no autorizado por el administrador"
    fi

    unset pending_authorizations[$chat_id]
}

# Función para obtener actualizaciones usando offset
obtener_actualizaciones() {
    local offset=$1
    curl -s "$URL/getUpdates?offset=$offset"
}

# Función para enviar la solicitud de recarga a Movistar
enviar_solicitud() {
    local chat_id=$1
    local numero=$2
    local productId=${user_productId[$chat_id]}
    local mensaje=${user_message[$chat_id]}

    # Cuerpo de la solicitud
    local data_json="{\"transactionId\":\"063418772\",\"saleTransactionId\":\"23175128284\",\"appName\":\"MOBILEAPP\",\"campaignId\":1183,\"offerId\":1168,\"productId\":\"$productId\",\"msisdn\":\"56$numero\"}"

    log_msg "Enviando recarga para 56${numero}, productId: ${productId}"
    local response
    response=$(curl -v -s "${CABECERAS[@]}" \
        --data-binary "$data_json" \
        'https://apix.movistar.cl/productOrderingManagement/allowanceOOS/purchaseOfferOOS' 2>> curl.log)

    log_msg "Respuesta: ${response}"
    
    if echo "$response" | grep -q '"errorCode":""'; then
        enviar_mensaje "$chat_id" "✅ Recarga exitosa en ${numero}: ${mensaje}"
    else
        enviar_mensaje "$chat_id" "❌ Error en la recarga para ${numero}: ${mensaje}"
    fi

    unset user_state[$chat_id]
    unset user_productId[$chat_id]
    unset user_message[$chat_id]
    # Una vez procesada la solicitud, se muestra nuevamente el menú de bienvenida.
    mostrar_menu "$chat_id"
}

# Función para consultar el saldo
consultar_saldo() {
    local chat_id=$1
    local numero=$2
    local temp_file=".saldo"

    # Realizar la consulta de saldo y guardar en .saldo
    curl -s -X GET "https://apix.movistar.cl/customer/V2/balance?msisdn=56$numero" \
        "${CABECERAS[@]}" \
        --compressed -o "$temp_file"  # ¡Aquí está la clave! --compressed descomprime la respuesta

    # Extraer valores del archivo .saldo
    local saldo=$(grep -Po '"saldoRecarga"\s*:\s*"\K[^"]+' "$temp_file")
    local vigencia=$(grep -Po '"fechaVigencia"\s*:\s*"\K[^"]+' "$temp_file")
    local estado=$(grep -Po '"estadoVigencia"\s*:\s*"\K[^"]+' "$temp_file")

    # Construir el mensaje
    local mensaje_saldo="Información para el número: 56$numero\n\n"
    mensaje_saldo+="Saldo: $saldo\n"
    mensaje_saldo+="Vigencia: $vigencia\n"
    mensaje_saldo+="Estado de vigencia: $estado"

    # Enviar el mensaje y limpiar el archivo temporal
    enviar_mensaje "$chat_id" "$mensaje_saldo"
    rm -f "$temp_file"
    log_msg "Consulta de saldo realizada para 56${numero}"
}

# Función para procesar los mensajes recibidos
procesar_mensaje() {
    local mensaje_json="$1"
    local chat_id
    chat_id=$(echo "$mensaje_json" | jq -r '.message.chat.id')
    local mensaje_texto
    mensaje_texto=$(echo "$mensaje_json" | jq -r '.message.text')
    local username
    username=$(echo "$mensaje_json" | jq -r '.message.from.username')
    local first_name
    first_name=$(echo "$mensaje_json" | jq -r '.message.from.first_name')
    local last_name
    local last_name=$(echo "$mensaje_json" | jq -r '.message.from.last_name')

    log_msg "Mensaje recibido de ${chat_id}: ${mensaje_texto}"

    # Si el chat_id es el del administrador, verificar si es una respuesta de autorización
    if [[ "$chat_id" == "$ADMIN_CHAT_ID" ]]; then
        if [[ -n "${pending_authorizations[$chat_id]}" ]]; then
            procesar_respuesta_admin "$chat_id" "$mensaje_texto"
            return
        fi
    fi

    # Si el usuario no está autorizado, no procesar más comandos
    if [[ ${user_authorized[$chat_id]} -ne 1 ]]; then
        # Si es la primera interacción del día, notificar al administrador
        if [[ -z ${user_first_interaction[$chat_id]} ]]; then
            user_first_interaction[$chat_id]=1
            notificar_admin "$chat_id" "$username" "$first_name" "$last_name"
        fi
        enviar_mensaje "$chat_id" "⏳ Esperando autorización del administrador..."
        return
    fi

    # Si el usuario estaba en proceso de recarga (esperando el número)
    if [[ "${user_state[$chat_id]}" == "esperando_numero" ]]; then
        if [[ "$mensaje_texto" =~ ^[0-9]{9}$ ]]; then
            enviar_solicitud "$chat_id" "$mensaje_texto"
        else
            enviar_mensaje "$chat_id" "❌ Número inválido. Ingresa un número de 9 dígitos:"
            log_msg "Número inválido recibido de ${chat_id}: ${mensaje_texto}"
            unset user_state[$chat_id]
            unset user_productId[$chat_id]
            unset user_message[$chat_id]
            # Si el número es inválido, se muestra el menú para reiniciar la conversación.
            mostrar_menu "$chat_id"
        fi
        return
    fi

    # Si el usuario estaba esperando un número para consultar saldo
    if [[ "${user_state[$chat_id]}" == "esperando_numero_consulta" ]]; then
        if [[ "$mensaje_texto" =~ ^[0-9]{9}$ ]]; then
            consultar_saldo "$chat_id" "$mensaje_texto"
            unset user_state[$chat_id]
        else
            enviar_mensaje "$chat_id" "❌ Número inválido. Ingresa un número de 9 dígitos:"
            log_msg "Número inválido recibido de ${chat_id}: ${mensaje_texto}"
        fi
        return
    fi

    # Si no está esperando el número, procesamos el comando recibido
    case $mensaje_texto in
        "/start")
            mostrar_menu "$chat_id"
            ;;
        "1")
            user_productId[$chat_id]="2185"
            user_message[$chat_id]="GB Libres x 10D (2300)"
            user_state[$chat_id]="esperando_numero"
            enviar_mensaje "$chat_id" "Ingrese el número a recargar (9 dígitos):"
            log_msg "Opción 1 seleccionada por ${chat_id}"
            ;;
        "2")
            user_productId[$chat_id]="2209"
            user_message[$chat_id]="Ilimitado x 10D (2750)"
            user_state[$chat_id]="esperando_numero"
            enviar_mensaje "$chat_id" "Ingrese el número a recargar (9 dígitos):"
            log_msg "Opción 2 seleccionada por ${chat_id}"
            ;;
        "3")
            user_productId[$chat_id]="2332"
            user_message[$chat_id]="GB Libres x 3D (1300)"
            user_state[$chat_id]="esperando_numero"
            enviar_mensaje "$chat_id" "Ingrese el número a recargar (9 dígitos):"
            log_msg "Opción 3 seleccionada por ${chat_id}"
            ;;
        "4")
            user_productId[$chat_id]="2644"
            user_message[$chat_id]="Ilimitado x 12D (3050)"
            user_state[$chat_id]="esperando_numero"
            enviar_mensaje "$chat_id" "Ingrese el número a recargar (9 dígitos):"
            log_msg "Opción 4 seleccionada por ${chat_id}"
            ;;
        "5")
            user_state[$chat_id]="esperando_numero_consulta"
            enviar_mensaje "$chat_id" "Ingrese el número a consultar (9 dígitos):"
            log_msg "Opción 5 seleccionada por ${chat_id}"
            ;;
        "0")
            enviar_mensaje "$chat_id" "Saliendo del menú..."
            log_msg "${chat_id} salió del menú"
            mostrar_menu "$chat_id"
            ;;
        *)
            # Cualquier otro mensaje muestra el menú de bienvenida.
            mostrar_menu "$chat_id"
            ;;
    esac
}

# Bucle principal
LAST_UPDATE_ID=0
while true; do
    updates=$(obtener_actualizaciones $((LAST_UPDATE_ID + 1)))
    while IFS= read -r update; do
        update_id=$(echo "$update" | jq -r '.update_id')
        procesar_mensaje "$update"
        LAST_UPDATE_ID=$update_id
    done < <(echo "$updates" | jq -c '.result[]')
    sleep 2
done
