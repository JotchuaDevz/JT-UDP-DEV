#!/bin/bash

CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="$CONFIG_DIR/config.json"
USER_DB="$CONFIG_DIR/udpusers.db"
SYSTEMD_SERVICE="/etc/systemd/system/hysteria-server.service"
SCRIPT_PATH="$0"

mkdir -p "$CONFIG_DIR"
touch "$USER_DB"

# Zona horaria Manila/Filipinas
export TZ="Asia/Manila"

# Obtener IP del servidor
get_server_ip() {
    local ip=""

    if command -v curl >/dev/null 2>&1; then
        ip=$(curl -s -4 ifconfig.me 2>/dev/null) || \
        ip=$(curl -s -4 icanhazip.com 2>/dev/null) || \
        ip=$(curl -s -4 ipecho.net/plain 2>/dev/null)
    fi

    if [[ -z "$ip" ]] && command -v wget >/dev/null 2>&1; then
        ip=$(wget -qO- ifconfig.me 2>/dev/null) || \
        ip=$(wget -qO- icanhazip.com 2>/dev/null)
    fi

    if [[ -z "$ip" ]]; then
        ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127' | head -n 1)
    fi

    if [[ -z "$ip" ]]; then
        ip=$(hostname -I | awk '{print $1}')
    fi

    echo "$ip"
}

# Limpiar pantalla después de un comando
limpiar_despues_de_comando() {
    echo -e "\nPresiona Enter para continuar..."
    read
    clear
    mostrar_banner
}

obtener_usuarios() {
    if [[ -f "$USER_DB" ]]; then
        sqlite3 "$USER_DB" "SELECT username || ':' || password FROM users;" | paste -sd, -
    fi
}

actualizar_config_usuarios() {
    local usuarios=$(obtener_usuarios)
    local array_usuarios=$(echo "$usuarios" | awk -F, '{for(i=1;i<=NF;i++) printf "\"" $i "\"" ((i==NF) ? "" : ",")}')
    jq ".auth.config = [$array_usuarios]" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

generar_uri_hysteria() {
    local usuario="$1"
    local contrasena="$2"
    local ip_servidor="$3"
    local obfs="$4"

    local up_mbps=$(jq -r ".up_mbps" "$CONFIG_FILE")
    local down_mbps=$(jq -r ".down_mbps" "$CONFIG_FILE")
    local insecure=$(jq -r ".insecure" "$CONFIG_FILE")
    local listen="127.0.0.1:1080"
    local puerto="36712"
    local recv_window_conn="4194304"

    echo "udp-hysteria-labx://${ip_servidor}:${puerto}?auth=${usuario}%3A${contrasena}&obfs=${obfs}&up_mbps=${up_mbps}&down_mbps=${down_mbps}&listen=${listen}&recv_window_conn=${recv_window_conn}&insecure=${insecure}&retry_interval=1"
}

mostrar_info_conexion() {
    local usuario="$1"
    local contrasena="$2"
    local ip_servidor=$(get_server_ip)
    local obfs=$(jq -r ".obfs" "$CONFIG_FILE")
    local uri=$(generar_uri_hysteria "$usuario" "$contrasena" "$ip_servidor" "$obfs")

    echo -e "\n\e[1;33m═══════════ Información de Conexión ═══════════\e[0m"
    echo -e "\e[1;32mIP del Servidor : \e[0m$ip_servidor"
    echo -e "\e[1;32mUsuario         : \e[0m$usuario"
    echo -e "\e[1;32mContraseña      : \e[0m$contrasena"
    echo -e "\e[1;32mPuerto UDP      : \e[0m10000-65000"
    echo -e "\e[1;32mOBFS            : \e[0m$obfs"
    echo -e "\e[1;33m═══════════════════════════════════════════════\e[0m"
    echo -e "\n\e[1;33m═══════════ URI para la App ═══════════\e[0m"
    echo -e "\e[1;36m$uri\e[0m"
    echo -e "\e[1;33m═══════════════════════════════════════\e[0m"
}

agregar_usuario() {
    echo -e "\n\e[1;34mIngresa el nombre de usuario:\e[0m"
    read -r usuario
    echo -e "\e[1;34mIngresa la contraseña:\e[0m"
    read -r contrasena
    sqlite3 "$USER_DB" "INSERT INTO users (username, password) VALUES ('$usuario', '$contrasena');"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mUsuario $usuario agregado exitosamente.\e[0m"
        mostrar_info_conexion "$usuario" "$contrasena"
        actualizar_config_usuarios
        reiniciar_servidor
    else
        echo -e "\e[1;31mError: No se pudo agregar el usuario $usuario.\e[0m"
    fi
    limpiar_despues_de_comando
}

editar_usuario() {
    echo -e "\n\e[1;34mIngresa el nombre de usuario a editar:\e[0m"
    read -r usuario
    echo -e "\e[1;34mIngresa la nueva contraseña:\e[0m"
    read -r contrasena
    sqlite3 "$USER_DB" "UPDATE users SET password = '$contrasena' WHERE username = '$usuario';"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mUsuario $usuario actualizado exitosamente.\e[0m"
        mostrar_info_conexion "$usuario" "$contrasena"
        actualizar_config_usuarios
        reiniciar_servidor
    else
        echo -e "\e[1;31mError: No se pudo actualizar el usuario $usuario.\e[0m"
    fi
    limpiar_despues_de_comando
}

eliminar_usuario() {
    echo -e "\n\e[1;34mIngresa el nombre de usuario a eliminar:\e[0m"
    read -r usuario
    sqlite3 "$USER_DB" "DELETE FROM users WHERE username = '$usuario';"
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mUsuario $usuario eliminado exitosamente.\e[0m"
        actualizar_config_usuarios
        reiniciar_servidor
    else
        echo -e "\e[1;31mError: No se pudo eliminar el usuario $usuario.\e[0m"
    fi
    limpiar_despues_de_comando
}

mostrar_usuarios() {
    local ip_servidor=$(get_server_ip)
    local obfs=$(jq -r ".obfs" "$CONFIG_FILE")

    echo -e "\n\e[1;33m═══════════ Usuarios Actuales ═══════════\e[0m"

    while IFS='|' read -r usuario contrasena; do
        local uri=$(generar_uri_hysteria "$usuario" "$contrasena" "$ip_servidor" "$obfs")
        echo -e "\e[1;32mUsuario    : \e[0m$usuario"
        echo -e "\e[1;32mContraseña : \e[0m$contrasena"
        echo -e "\e[1;36mURI        : \e[0m$uri"
        echo -e "\e[1;33m─────────────────────────────────────────\e[0m"
    done < <(sqlite3 "$USER_DB" "SELECT username, password FROM users;")

    limpiar_despues_de_comando
}

cambiar_velocidad_subida() {
    echo -e "\n\e[1;34mIngresa la nueva velocidad de subida (Mbps):\e[0m"
    read -r velocidad_subida
    jq ".up_mbps = $velocidad_subida" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".up = \"$velocidad_subida Mbps\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mVelocidad de subida cambiada a $velocidad_subida Mbps exitosamente.\e[0m"
    reiniciar_servidor
    limpiar_despues_de_comando
}

cambiar_velocidad_bajada() {
    echo -e "\n\e[1;34mIngresa la nueva velocidad de bajada (Mbps):\e[0m"
    read -r velocidad_bajada
    jq ".down_mbps = $velocidad_bajada" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    jq ".down = \"$velocidad_bajada Mbps\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mVelocidad de bajada cambiada a $velocidad_bajada Mbps exitosamente.\e[0m"
    reiniciar_servidor
    limpiar_despues_de_comando
}

cambiar_servidor() {
    echo -e "\n\e[1;34mIngresa la nueva dirección del servidor (ej: ejemplo.com):\e[0m"
    read -r servidor
    jq ".server = \"$servidor\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mServidor cambiado a $servidor exitosamente.\e[0m"
    reiniciar_servidor
    limpiar_despues_de_comando
}

cambiar_obfs() {
    echo -e "\n\e[1;34mIngresa el nuevo método OBFS (ej: tfn, tls, etc.):\e[0m"
    read -r metodo_obfs
    jq ".obfs = \"$metodo_obfs\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mMétodo OBFS cambiado a $metodo_obfs exitosamente.\e[0m"
    reiniciar_servidor
    limpiar_despues_de_comando
}

cambiar_insecure() {
    local actual=$(jq -r ".insecure" "$CONFIG_FILE")
    echo -e "\n\e[1;34mValor actual de insecure: \e[1;33m$actual\e[0m"
    echo -e "\e[1;34mSelecciona el nuevo valor:\e[0m"
    echo -e "\e[1;32m[1]\e[0m true  (omitir verificación de certificado)"
    echo -e "\e[1;32m[2]\e[0m false (verificar certificado)"
    read -r opcion_insecure
    case $opcion_insecure in
        1) valor_insecure="true" ;;
        2) valor_insecure="false" ;;
        *) echo -e "\e[1;31mOpción inválida.\e[0m"; limpiar_despues_de_comando; return ;;
    esac
    jq ".insecure = $valor_insecure" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mInsecure cambiado a $valor_insecure exitosamente.\e[0m"
    reiniciar_servidor
    limpiar_despues_de_comando
}

cambiar_puerto_udp() {
    echo -e "\n\e[1;34mIngresa el nuevo puerto UDP:\e[0m"
    read -r puerto_udp
    jq ".udp_port = $puerto_udp" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "\e[1;32mPuerto UDP cambiado a $puerto_udp exitosamente.\e[0m"
    reiniciar_servidor
    limpiar_despues_de_comando
}

reiniciar_servidor() {
    systemctl restart hysteria-server
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mServidor reiniciado exitosamente.\e[0m"
    else
        echo -e "\e[1;31mError: No se pudo reiniciar el servidor.\e[0m"
    fi
}

mostrar_ram_y_nucleos() {
    local ram_total=$(free -m | awk '/Mem:/ { print $2 }')
    local ram_usada=$(free -m | awk '/Mem:/ { print $3 }')
    local nucleos=$(nproc)

    echo -e "\e[1;35mUso de RAM: $ram_usada/$ram_total MB | Núcleos CPU: $nucleos\e[0m"
}

desinstalar_servidor() {
    echo -e "\n\e[1;34mDesinstalando servidor TFN-UDP...\e[0m"
    systemctl stop hysteria-server
    systemctl disable hysteria-server
    rm -f "$SYSTEMD_SERVICE"
    systemctl daemon-reload
    rm -rf "$CONFIG_DIR"
    rm -f /usr/local/bin/hysteria
    echo -e "\e[1;32mServidor TFN-UDP desinstalado exitosamente.\e[0m"

    cat > /tmp/remove_script.sh << EOF
#!/bin/bash
sleep 1
rm -f "$SCRIPT_PATH"
rm -f /tmp/remove_script.sh
EOF

    chmod +x /tmp/remove_script.sh
    echo -e "\e[1;32mEliminando script del menú...\e[0m"
    nohup /tmp/remove_script.sh >/dev/null 2>&1 &

    exit 0
}

mostrar_banner() {
    clear
    echo -e "\e[1;36m╔═══════════════════════════════════════╗"
    echo -e "║         Gestor JT-UDP                ║"
    echo -e "║                                       ║"
    echo -e "║       Telegram: @Jotchua_Devz            ║"
    echo -e "╚═══════════════════════════════════════╝\e[0m"
    echo -e "\e[1;33mHora del Servidor : $(TZ='Asia/Manila' date '+%I:%M %p')"
    echo -e "Zona Horaria      : Manila/Filipinas"
    echo -e "Fecha             : $(TZ='Asia/Manila' date '+%Y-%m-%d')\e[0m"
    mostrar_ram_y_nucleos
}

mostrar_menu() {
    echo -e "\e[1;36m╔═══════════════════════════════════════╗"
    echo -e "║           Gestor UDP                                            ║"
    echo -e "╚═══════════════════════════════════════╝\e[0m"
    echo -e "\e[1;32m[\e[0m1\e[1;32m]\e[0m  Agregar usuario"
    echo -e "\e[1;32m[\e[0m2\e[1;32m]\e[0m  Editar contraseña de usuario"
    echo -e "\e[1;32m[\e[0m3\e[1;32m]\e[0m  Eliminar usuario"
    echo -e "\e[1;32m[\e[0m4\e[1;32m]\e[0m  Mostrar usuarios"
    echo -e "\e[1;32m[\e[0m5\e[1;32m]\e[0m  Cambiar velocidad de subida"
    echo -e "\e[1;32m[\e[0m6\e[1;32m]\e[0m  Cambiar velocidad de bajada"
    echo -e "\e[1;32m[\e[0m7\e[1;32m]\e[0m  Cambiar dominio"
    echo -e "\e[1;32m[\e[0m8\e[1;32m]\e[0m  Cambiar OBFS"
    echo -e "\e[1;32m[\e[0m9\e[1;32m]\e[0m  Cambiar insecure"
    echo -e "\e[1;32m[\e[0m10\e[1;32m]\e[0m Desinstalar script"
    echo -e "\e[1;32m[\e[0m0\e[1;32m]\e[0m  Salir"
    echo -e "\e[1;36m═══════════════════════════════════════\e[0m"
    echo -e "\e[1;32mIngresa tu opción:\e[0m"
}

mostrar_banner
while true; do
    mostrar_menu
    read -r opcion
    case $opcion in
        1)  agregar_usuario ;;
        2)  editar_usuario ;;
        3)  eliminar_usuario ;;
        4)  mostrar_usuarios ;;
        5)  cambiar_velocidad_subida ;;
        6)  cambiar_velocidad_bajada ;;
        7)  cambiar_servidor ;;
        8)  cambiar_obfs ;;
        9)  cambiar_insecure ;;
        10) desinstalar_servidor ;;
        0)  clear; exit 0 ;;
        *)  echo -e "\e[1;31mOpción inválida. Intenta de nuevo.\e[0m"; limpiar_despues_de_comando ;;
    esac
done
