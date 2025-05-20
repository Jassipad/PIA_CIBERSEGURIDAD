#!/bin/bash

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables configurables
interface=""
monitoring_time=60
output_file=""
packet_count=100
target_ip=""
ping_interval=1
os_type=""

# Detectar sistema operativo
detect_os() {
    case "$(uname -s)" in
        Linux*)     os_type="Linux";;
        Darwin*)    os_type="Mac";;
        CYGWIN*|MINGW*|MSYS*) os_type="Windows";;
        *)          os_type="UNKNOWN"
    esac
}

# Verificar si el usuario tiene privilegios
check_privileges() {
    if [[ "$os_type" == "Linux" || "$os_type" == "Mac" ]] && [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Error: Este script requiere privilegios de root/admin${NC}"
        exit 1
    elif [[ "$os_type" == "Windows" ]] && ! net session >/dev/null 2>&1; then
        echo -e "${RED}Error: Ejecute como administrador${NC}"
        exit 1
    fi
}

# Mostrar interfaces disponibles
list_interfaces() {
    echo -e "\n${YELLOW}Interfaces disponibles:${NC}"
    case "$os_type" in
        "Linux")
            ip -br link show | awk '{print $1}' | grep -v "lo"
            ;;
        "Mac")
            networksetup -listallhardwareports | awk -F': ' '/Device:/ {print $2}'
            ;;
        "Windows")
            ipconfig | awk -F': ' '/adaptador/ {print $2}'
            ;;
        *)
            echo -e "${RED}Sistema operativo no soportado${NC}"
            exit 1
            ;;
    esac
}

# Validar dirección IP
validate_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 &&
           ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Validar nombre de dominio
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Mostrar menú principal
show_menu() {
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}      HERRAMIENTA DE MONITOREO DE RED       ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo -e "1. ${GREEN}Configurar interfaz de red${NC}"
    echo -e "2. ${GREEN}Monitorear tráfico general${NC}"
    echo -e "3. ${GREEN}Analizar conexiones activas${NC}"
    echo -e "4. ${GREEN}Monitorear ancho de banda${NC}"
    echo -e "5. ${GREEN}Realizar ping continuo${NC}"
    echo -e "6. ${GREEN}Rastreo de ruta (traceroute)${NC}"
    echo -e "7. ${GREEN}Prueba de velocidad${NC}"
    echo -e "8. ${GREEN}Escaneo de puertos${NC}"
    echo -e "9. ${GREEN}Configurar parámetros avanzados${NC}"
    echo -e "10. ${RED}Salir${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo -n "Seleccione una opción [1-10]: "
}

# Configurar interfaz de red
set_interface() {
    list_interfaces
    
    echo -n "Ingrese el nombre de la interfaz: "
    read interface
    
    case "$os_type" in
        "Linux")
            if ! ip link show | grep -q "$interface:"; then
                echo -e "${RED}Error: Interfaz no válida${NC}"
                interface=""
                return 1
            fi
            ;;
        "Mac")
            if ! ifconfig "$interface" >/dev/null 2>&1; then
                echo -e "${RED}Error: Interfaz no válida${NC}"
                interface=""
                return 1
            fi
            ;;
        "Windows")
            if ! ipconfig | grep -q "$interface"; then
                echo -e "${RED}Error: Interfaz no válida${NC}"
                interface=""
                return 1
            fi
            ;;
    esac
    
    echo -e "${GREEN}Interfaz configurada correctamente: $interface${NC}"
    sleep 1
}

# Monitorear tráfico general
general_traffic() {
    if [[ -z "$interface" ]]; then
        echo -e "${RED}Error: Configure primero una interfaz${NC}"
        sleep 2
        return
    fi
    
    echo -e "\n${BLUE}Monitoreando tráfico en $interface (${monitoring_time}s)...${NC} (no monitorea trafico real pero simula salidas de interfaz)"
    
    case "$os_type" in
        "Linux"|"Mac")
            timeout $monitoring_time tcpdump -i "$interface" -c "$packet_count"
            ;;
        "Windows")
            timeout $monitoring_time bash -c "while true; do ipconfig /all | grep -A10 \"$interface\"; echo '------------------------'; sleep 2; done"
            ;;
    esac
}

# Analizar conexiones activas
active_connections() {
    echo -e "\n${YELLOW}Conexiones activas:${NC}"
    
    case "$os_type" in
        "Linux"|"Mac")
            ss -tulnp
            echo -e "\n${YELLOW}Resumen:${NC}"
            echo -e "  Conexiones TCP: $(ss -t | wc -l)"
            echo -e "  Conexiones UDP: $(ss -u | wc -l)"
            echo -e "  Conexiones en escucha: $(ss -l | wc -l)"
            ;;
        "Windows")
            netstat -ano
            echo -e "\n${YELLOW}Resumen:${NC}"
            echo -e "  Conexiones TCP: $(netstat -ano | grep -c 'TCP')"
            echo -e "  Conexiones UDP: $(netstat -ano | grep -c 'UDP')"
            echo -e "  Conexiones en escucha: $(netstat -ano | grep -c 'LISTENING')"
            ;;
    esac
    
    read -p "¿Mostrar procesos asociados? [s/n]: " show_procs
    if [[ $show_procs =~ ^[sSyY]$ ]]; then
        case "$os_type" in
            "Linux"|"Mac") ps aux | head;;
            "Windows") tasklist | head;;
        esac
    fi
}

# Monitorear ancho de banda
bandwidth_monitor() {
    if [[ -z "$interface" ]]; then
        echo -e "${RED}Error: Configure primero una interfaz${NC}"
        sleep 2
        return
    fi
    
    echo -e "\n${BLUE}Monitoreando ancho de banda en $interface (${monitoring_time}s)...${NC}"
    
    case "$os_type" in
        "Linux")
            initial_rx=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
            initial_tx=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)
            sleep "$monitoring_time"
            final_rx=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
            final_tx=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)
            
            rx_rate=$(( (final_rx - initial_rx) / monitoring_time / 1024 ))
            tx_rate=$(( (final_tx - initial_tx) / monitoring_time / 1024 ))
            
            echo -e "\n${YELLOW}Estadísticas:${NC}"
            echo -e "  Velocidad de recepción: $rx_rate KB/s"
            echo -e "  Velocidad de transmisión: $tx_rate KB/s"
            ;;
        "Mac")
            initial_stats=$(netstat -I "$interface" -b | awk '/'"$interface"'/{print $7,$10}')
            sleep "$monitoring_time"
            final_stats=$(netstat -I "$interface" -b | awk '/'"$interface"'/{print $7,$10}')
            
            initial_rx=$(echo "$initial_stats" | awk '{print $1}')
            initial_tx=$(echo "$initial_stats" | awk '{print $2}')
            final_rx=$(echo "$final_stats" | awk '{print $1}')
            final_tx=$(echo "$final_stats" | awk '{print $2}')
            
            rx_rate=$(( (final_rx - initial_rx) / monitoring_time / 1024 ))
            tx_rate=$(( (final_tx - initial_tx) / monitoring_time / 1024 ))
            
            echo -e "\n${YELLOW}Estadísticas:${NC}"
            echo -e "  Velocidad de recepción: $rx_rate KB/s"
            echo -e "  Velocidad de transmisión: $tx_rate KB/s"
            ;;
        "Windows")
        #esta parte del codigo nop jala --------------------------------------------
	    initial_stats=$(netsh interface ipv4 show interfaces | findstr "$interface")
            sleep "$monitoring_time"
            final_stats=$(netsh interface ipv4 show interfaces | findstr "$interface")
            
            echo -e "\n${YELLOW}Estadísticas:${NC}"
            echo "$initial_stats" | awk '{print "  Bytes enviados iniciales: " $6}'
            echo "$final_stats" | awk '{print "  Bytes enviados finales: " $6}'
            echo "$initial_stats" | awk '{print "  Bytes recibidos iniciales: " $9}'
            echo "$final_stats" | awk '{print "  Bytes recibidos finales: " $9}'        

            ;;
    esac
}

# Realizar ping continuo
continuous_ping() {
    echo -n "Ingrese IP/Dominio para hacer ping: "
    read target_ip
    
    if [[ -z "$target_ip" ]]; then
        echo -e "${RED}Error: Debe especificar un objetivo${NC}"
        return 1
    fi
    
    if ! validate_ip "$target_ip" && ! validate_domain "$target_ip"; then
        echo -e "${RED}Error: Dirección IP o dominio no válido${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}Iniciando ping a $target_ip (Ctrl+C para detener)...${NC}"
    
    case "$os_type" in
        "Linux"|"Mac") ping -c "$packet_count" -i "$ping_interval" "$target_ip";;
        "Windows") ping -n "$packet_count" "$target_ip";;
    esac
}

# Rastreo de ruta
trace_route() {
    echo -n "Ingrese IP/Dominio para rastrear: "
    read target_ip
    
    if [[ -z "$target_ip" ]]; then
        echo -e "${RED}Error: Debe especificar un objetivo${NC}"
        return 1
    fi
    
    if ! validate_ip "$target_ip" && ! validate_domain "$target_ip"; then
        echo -e "${RED}Error: Dirección IP o dominio no válido${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}Realizando traceroute a $target_ip...${NC}"
    
    case "$os_type" in
        "Linux"|"Mac") traceroute "$target_ip";;
        "Windows") tracert "$target_ip";;
    esac
}

# Prueba de velocidad
# por algun motivo no lee el api-----------------------------
speed_test() {
    echo -e "\n${YELLOW}Iniciando prueba de velocidad...${NC}"
    
    case "$os_type" in
        "Linux"|"Mac")
            if ! command -v speedtest-cli &> /dev/null; then
                echo -e "${RED}Error: Instale speedtest-cli primero${NC}"
                echo "Pruebe con: sudo apt install speedtest-cli"
                return 1
            fi
            speedtest-cli --simple
            ;;
        "Windows")
            if ! command -v speedtest &> /dev/null; then
                echo -e "${RED}Error: Instale speedtest primero${NC}"
                echo "Descargue de: https://www.speedtest.net/apps/cli"
                return 1
            fi
            speedtest.exe
            ;;
    esac
}

# Escaneo de puertos
port_scan() {
    echo -n "Ingrese IP/Dominio a escanear: "
    read target_ip
    
    if [[ -z "$target_ip" ]]; then
        echo -e "${RED}Error: Debe especificar un objetivo${NC}"
        return 1
    fi
    
    if ! validate_ip "$target_ip" && ! validate_domain "$target_ip"; then
        echo -e "${RED}Error: Dirección IP o dominio no válido${NC}"
        return 1
    fi
    
    echo -n "Ingrese rango de puertos (ej: 80-443): "
    read port_range
    
    echo -e "\n${BLUE}Escaneando puertos $port_range en $target_ip...${NC}"
    
    case "$os_type" in
        "Linux"|"Mac")
            if ! command -v nc &> /dev/null; then
                echo -e "${RED}Error: Instale netcat primero${NC}"
                return 1
            fi
            start_port=$(echo "$port_range" | cut -d'-' -f1)
            end_port=$(echo "$port_range" | cut -d'-' -f2)
            
            for port in $(seq "$start_port" "$end_port"); do
                timeout 1 bash -c "echo >/dev/tcp/$target_ip/$port" 2>/dev/null &&
                    echo -e "${GREEN}Puerto $port: ABIERTO${NC}" ||
                    echo -e "${RED}Puerto $port: CERRADO${NC}"
            done
            ;;
        "Windows")
            if ! command -v Test-NetConnection &> /dev/null; then
                echo -e "${RED}Error: Cmdlet Test-NetConnection no disponible${NC}"
                return 1
            fi
            start_port=$(echo "$port_range" | cut -d'-' -f1)
            end_port=$(echo "$port_range" | cut -d'-' -f2)
            
            for port in $(seq "$start_port" "$end_port"); do
                if Test-NetConnection -ComputerName "$target_ip" -Port "$port" -InformationLevel Quiet; then
                    echo -e "${GREEN}Puerto $port: ABIERTO${NC}"
                else
                    echo -e "${RED}Puerto $port: CERRADO${NC}"
                fi
            done
            ;;
    esac
}

# Configuración avanzada
advanced_settings() {
    echo -e "\n${YELLOW}Configuración Avanzada:${NC}"
    
    echo -n "Tiempo de monitoreo (segundos) [actual: $monitoring_time]: "
    read new_time
    if [[ $new_time =~ ^[0-9]+$ ]] && (( new_time > 0 )); then
        monitoring_time=$new_time
    fi
    
    echo -n "Número de paquetes a capturar [actual: $packet_count]: "
    read new_count
    if [[ $new_count =~ ^[0-9]+$ ]] && (( new_count > 0 )); then
        packet_count=$new_count
    fi
    
    echo -n "Intervalo de ping (segundos) [actual: $ping_interval]: "
    read new_interval
    if [[ $new_interval =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$new_interval > 0" | bc -l) )); then
        ping_interval=$new_interval
    fi
    
    echo -n "Archivo para guardar resultados (dejar vacío para no guardar): "
    read output_file
    
    echo -e "${GREEN}Configuración avanzada actualizada${NC}"
    sleep 1
}

# Guardar resultados
save_results() {
    if [[ -n "$output_file" ]]; then
        # Sanitizar nombre de archivo
        output_file=$(echo "$output_file" | tr -d '[:space:]<>:"/\|?*')
        
        {
            echo "=== Resultados de Monitoreo de Red ==="
            echo "Fecha: $(date)"
            echo "Sistema Operativo: $os_type"
            echo "Interfaz: ${interface:-No configurada}"
            echo "Tiempo de monitoreo: $monitoring_time segundos"
            echo "Paquetes capturados: $packet_count"
            echo ""
            echo "=== Conexiones activas ==="
            case "$os_type" in
                "Linux"|"Mac") ss -tulnp;;
                "Windows") netstat -ano;;
            esac
            echo ""
            echo "=== Estadísticas de red ==="
            case "$os_type" in
                "Linux") ip -s link show "$interface";;
                "Mac") netstat -I "$interface" -b;;
                "Windows") netsh interface ipv4 show interfaces | findstr "$interface";;
            esac
        } > "$output_file"
        
        echo -e "${GREEN}Resultados guardados en $output_file${NC}"
    fi
}

# Manejar señal de salida
cleanup() {
    echo -e "\n${RED}Finalizando monitor...${NC}"
    save_results
    exit 0
}

# Configurar trap para Ctrl+C
trap cleanup INT

# Inicio del script
detect_os
check_privileges

# Bucle principal
while true; do
    show_menu
    read -r option
    
    case $option in
        1) set_interface;;
        2) general_traffic;;
        3) active_connections;;
        4) bandwidth_monitor;;
        5) continuous_ping;;
        6) trace_route;;
        7) speed_test;;
        8) port_scan;;
        9) advanced_settings;;
        10) 
            cleanup
            exit 0;;
        *) 
            echo -e "${RED}Opción no válida${NC}"
            sleep 1;;
    esac
    
    if [[ -n "$output_file" ]]; then
        save_results
    fi
    
    read -p "Presione Enter para continuar..." -r
done