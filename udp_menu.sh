#!/bin/bash

# ══════════════════════════════════════════════
#   COLORES & ESTILOS
# ══════════════════════════════════════════════
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
BG_BLACK='\033[40m'
RESET='\033[0m'

cls() { printf "\033[2J\033[H"; }

# ══════════════════════════════════════════════
#   BARRA DE PROGRESO ANIMADA
# ══════════════════════════════════════════════
barra_progreso() {
    local label="$1"
    local total=40
    echo ""
    echo -e "  ${DIM}${W}${label}${RESET}"
    echo ""
    echo -ne "  ${DIM}[${RESET}"
    for i in $(seq 1 $total); do
        sleep 0.05
        if   [ $i -le 13 ]; then echo -ne "${R}━${RESET}"
        elif [ $i -le 26 ]; then echo -ne "${Y}━${RESET}"
        else                      echo -ne "${G}━${RESET}"
        fi
    done
    echo -e "${DIM}]${RESET}  ${G}${BOLD}100%${RESET}"
    echo ""
}

# ══════════════════════════════════════════════
#   CABECERA
# ══════════════════════════════════════════════
cabecera() {
    cls
    echo ""
    echo -e "  ${M}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${C}${BOLD}  ██╗   ██╗██████╗ ██████╗ ${RESET}                  ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${C}${BOLD}  ██║   ██║██╔══██╗██╔══██╗${RESET}                  ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${C}${BOLD}  ██║   ██║██║  ██║██████╔╝${RESET}                  ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${C}${BOLD}  ██║   ██║██║  ██║██╔═══╝ ${RESET}                  ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${C}${BOLD}  ╚██████╔╝██████╔╝██║     ${RESET}${DIM}${W}Installer v2.0${RESET}   ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${C}${BOLD}   ╚═════╝ ╚═════╝ ╚═╝     ${RESET}                  ${M}║${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}╠═══════════════════════════════════════════════╣${RESET}"
    echo -e "  ${M}║${RESET}  ${DIM}${W}  Protocol  ›  UDP  ›  Hysteria Stack        ${RESET}  ${M}║${RESET}"
    echo -e "  ${M}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
}

# ══════════════════════════════════════════════
#   PANTALLA DE INSTALACIÓN
# ══════════════════════════════════════════════
pantalla_instalando() {
    local nombre="$1"
    local color="$2"
    cls
    echo ""
    echo -e "  ${M}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}║${RESET}       ${color}${BOLD}⚡  Instalando  ${nombre}  ⚡${RESET}         ${M}║${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}╚═══════════════════════════════════════════════╝${RESET}"
}

# ══════════════════════════════════════════════
#   PEDIR CONTRASEÑA PARA ZIVPN
# ══════════════════════════════════════════════
pedir_password_zivpn() {
    cls
    echo ""
    echo -e "  ${M}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${G}${BOLD}   🔐  Configuración de ZiVPN              ${RESET}  ${M}║${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}╠═══════════════════════════════════════════════╣${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${W}Ingresa una contraseña para el servidor.${RESET}   ${M}║${RESET}"
    echo -e "  ${M}║${RESET}  ${DIM}Ejemplo: ${G}RequestLabX${RESET}                        ${M}║${RESET}"
    echo -e "  ${M}║${RESET}                                               ${M}║${RESET}"
    echo -e "  ${M}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "  ${M}❯${RESET} ${W}Contraseña: ${RESET}"
    read -r ZIVPN_PASSWORD
    # Si no pone nada, usar default
    if [[ -z "$ZIVPN_PASSWORD" ]]; then
        ZIVPN_PASSWORD="RequestLabX"
    fi
    echo ""
    echo -e "  ${DIM}Contraseña configurada: ${G}${BOLD}${ZIVPN_PASSWORD}${RESET}"
    echo ""
    sleep 0.8
}

# ══════════════════════════════════════════════
#   INSTALAR ZIVPN
# ══════════════════════════════════════════════
instalar_zivpn() {
    pedir_password_zivpn
    pantalla_instalando "ZiVPN" "${G}"
    barra_progreso "Descargando e instalando ZiVPN ..."

    bash <(curl -s https://raw.githubusercontent.com/JotchuaDevz/UDP-ZIVPN-MOD/refs/heads/main/install.sh) > /dev/null 2>&1

    echo -e "  ${M}┌─────────────────────────────────────────────┐${RESET}"
    echo -e "  ${M}│${RESET}  ${G}${BOLD}✔  ZiVPN instalado exitosamente            ${RESET} ${M}│${RESET}"
    echo -e "  ${M}│${RESET}  ${DIM}${W}Contraseña:${RESET} ${G}${BOLD}${ZIVPN_PASSWORD}${RESET}                  ${M}│${RESET}"
    echo -e "  ${M}│${RESET}  ${DIM}${W}Puerto UDP activo y listo para usar.${RESET}       ${M}│${RESET}"
    echo -e "  ${M}└─────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${DIM}Presiona ${Y}[ENTER]${RESET}${DIM} para regresar al menú...${RESET}"
    read -r
}

# ══════════════════════════════════════════════
#   INSTALAR HYSTERIA V1
# ══════════════════════════════════════════════
instalar_hysteria_v1() {
    pantalla_instalando "Hysteria v1" "${C}"
    barra_progreso "Descargando e instalando Hysteria v1 ..."

    bash <(curl -s https://raw.githubusercontent.com/JotchuaDevz/JT-UDP-DEV/refs/heads/main/install_udp.sh) > /dev/null 2>&1

    echo -e "  ${M}┌─────────────────────────────────────────────┐${RESET}"
    echo -e "  ${M}│${RESET}  ${G}${BOLD}✔  Hysteria v1 instalado exitosamente      ${RESET} ${M}│${RESET}"
    echo -e "  ${M}│${RESET}  ${DIM}${W}Servidor Hysteria UDP en marcha.${RESET}           ${M}│${RESET}"
    echo -e "  ${M}└─────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${DIM}Presiona ${Y}[ENTER]${RESET}${DIM} para regresar al menú...${RESET}"
    read -r
}

# ══════════════════════════════════════════════
#   MENÚ PRINCIPAL
# ══════════════════════════════════════════════
menu() {
    cabecera

    echo -e "  ${W}${BOLD}  ¿Qué deseas instalar?${RESET}"
    echo ""
    echo -e "  ${M}┌─────────────────────────────────────────────┐${RESET}"
    echo -e "  ${M}│${RESET}                                             ${M}│${RESET}"
    echo -e "  ${M}│${RESET}    ${BG_BLACK}${G} 1 ${RESET}  ${W}${BOLD}ZiVPN${RESET}       ${DIM}UDP Tunnel optimizado${RESET}       ${M}│${RESET}"
    echo -e "  ${M}│${RESET}                                             ${M}│${RESET}"
    echo -e "  ${M}│${RESET}    ${BG_BLACK}${C} 2 ${RESET}  ${W}${BOLD}Hysteria v1${RESET} ${DIM}Protocolo UDP clásico${RESET}       ${M}│${RESET}"
    echo -e "  ${M}│${RESET}                                             ${M}│${RESET}"
    echo -e "  ${M}│${RESET}    ${BG_BLACK}${R} 0 ${RESET}  ${DIM}${W}Salir${RESET}                                 ${M}│${RESET}"
    echo -e "  ${M}│${RESET}                                             ${M}│${RESET}"
    echo -e "  ${M}└─────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -ne "  ${M}❯${RESET} ${W}Opción: ${RESET}"
}

# ══════════════════════════════════════════════
#   LOOP PRINCIPAL
# ══════════════════════════════════════════════
while true; do
    menu
    read -r op

    case "$op" in
        1) instalar_zivpn ;;
        2) instalar_hysteria_v1 ;;
        0)
            cls
            echo ""
            echo -e "  ${M}╔═══════════════════════════════════════════════╗${RESET}"
            echo -e "  ${M}║${RESET}   ${Y}${BOLD}  Hasta luego. UDP Installer cerrado.  ${RESET}      ${M}║${RESET}"
            echo -e "  ${M}╚═══════════════════════════════════════════════╝${RESET}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "  ${R}  ✘  Opción inválida. Elige 1, 2 o 0.${RESET}"
            sleep 1
            ;;
    esac
done
