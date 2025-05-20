#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

target_ip=""
start_port=1
end_port=1024
scan_type="TCP"
output_file=""
timeout=1
ping_on_open=false
ping_mask="24"

# Función para verificar si un puerto TCP está abierto (compatible con Git Bash)
check_tcp_port() {
    local ip=$1
    local port=$2
    local result=1
    
    # Intentamos conectar con timeout
    (echo >/dev/tcp/$ip/$port) >/dev/null 2>&1 & pid=$!
    (sleep $timeout && kill $pid >/dev/null 2>&1) & watchdog=$!
    if wait $pid >/dev/null 2>&1; then
        result=0
    fi
    kill $watchdog >/dev/null 2>&1
    return $result
}

show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}       MENÚ DE ESCANEO DE PUERTOS       ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. ${GREEN}Configurar objetivo de escaneo${NC}"
    echo -e "2. ${GREEN}Configurar rango de puertos${NC}"
    echo -e "3. ${GREEN}Seleccionar tipo de escaneo${NC}"
    echo -e "4. ${GREEN}Configurar opciones avanzadas${NC}"
    echo -e "5. ${GREEN}Ejecutar escaneo${NC}"
    echo -e "6. ${GREEN}Mostrar configuración actual${NC}"
    echo -e "7. ${RED}Salir${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -n "Seleccione una opción [1-7]: "
}

set_target() {
    echo -n "Ingrese la dirección IP o hostname a escanear: "
    read target_ip
    
    if [[ ! $target_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ ! $target_ip =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo -e "${RED}Error: Dirección IP o hostname no válido${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Objetivo configurado correctamente: $target_ip${NC}"
    sleep 1
}

set_port_range() {
    echo -n "Ingrese el puerto inicial (1-65535): "
    read start_port
    echo -n "Ingrese el puerto final (1-65535): "
    read end_port
    
    if [[ ! $start_port =~ ^[0-9]+$ ]] || [[ ! $end_port =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Los puertos deben ser números${NC}"
        return 1
    fi
    
    if (( start_port < 1 || start_port > 65535 )); then
        echo -e "${RED}Error: Puerto inicial fuera de rango (1-65535)${NC}"
        return 1
    fi
    
    if (( end_port < 1 || end_port > 65535 )); then
        echo -e "${RED}Error: Puerto final fuera de rango (1-65535)${NC}"
        return 1
    fi
    
    if (( start_port > end_port )); then
        echo -e "${RED}Error: El puerto inicial no puede ser mayor al final${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Rango de puertos configurado correctamente: $start_port-$end_port${NC}"
    sleep 1
}

set_scan_type() {
    echo -e "${YELLOW}Seleccione el tipo de escaneo:${NC}"
    echo "1. TCP Connect Scan (recomendado)"
    echo "2. UDP Scan (no disponible en Git Bash)"
    echo -n "Opción [1-2]: "
    read scan_choice
    
    case $scan_choice in
        1) scan_type="TCP";;
        2) 
            echo -e "${RED}Escaneo UDP no está disponible en Git Bash${NC}"
            echo -e "${YELLOW}Usando TCP Scan por defecto${NC}"
            scan_type="TCP"
            sleep 2;;
        *) 
            echo -e "${RED}Opción no válida, usando TCP Scan por defecto${NC}"
            scan_type="TCP"
            sleep 1
            return 1;;
    esac
    
    echo -e "${GREEN}Tipo de escaneo configurado: $scan_type${NC}"
    sleep 1
}

set_advanced_options() {
    echo -e "${YELLOW}Opciones avanzadas:${NC}"
    
    echo -n "Tiempo de espera (timeout) en segundos (actual: $timeout): "
    read new_timeout
    if [[ $new_timeout =~ ^[0-9]+$ ]] && (( new_timeout > 0 )); then
        timeout=$new_timeout
    fi
    
    echo -n "Archivo para guardar resultados (dejar vacío para no guardar): "
    read output_file
    
    echo -n "¿Hacer ping a la red cuando se detecten puertos abiertos? [s/n] (actual: $([[ $ping_on_open == true ]] && echo "Sí" || echo "No")): "
    read ping_choice
    if [[ $ping_choice =~ ^[sSyY]$ ]]; then
        ping_on_open=true
        echo -n "Ingrese la máscara de red para el ping (ej. 24): "
        read ping_mask
        if [[ ! $ping_mask =~ ^[0-9]+$ ]] || (( ping_mask < 8 || ping_mask > 32 )); then
            echo -e "${RED}Máscara no válida, usando 24 por defecto${NC}"
            ping_mask="24"
        fi
    else
        ping_on_open=false
    fi
    
    echo -e "${GREEN}Opciones avanzadas configuradas${NC}"
    sleep 1
}

show_config() {
    echo -e "${YELLOW}Configuración actual:${NC}"
    echo -e "Objetivo: ${GREEN}$target_ip${NC}"
    echo -e "Rango de puertos: ${GREEN}$start_port-$end_port${NC}"
    echo -e "Tipo de escaneo: ${GREEN}$scan_type${NC}"
    echo -e "Timeout: ${GREEN}$timeout segundos${NC}"
    echo -e "Guardar resultados en: ${GREEN}${output_file:-"No se guardará"}${NC}"
    echo -e "Ping en puertos abiertos: ${GREEN}$([[ $ping_on_open == true ]] && echo "Sí (máscara /$ping_mask)" || echo "No")${NC}"
    echo -e "\nPresione Enter para continuar..."
    read
}

run_scan() {
    if [[ -z "$target_ip" ]]; then
        echo -e "${RED}Error: No se ha configurado un objetivo${NC}"
        sleep 2
        return
    fi
    
    echo -e "${BLUE}Iniciando escaneo de puertos...${NC}"
    echo -e "Objetivo: ${GREEN}$target_ip${NC}"
    echo -e "Puertos: ${GREEN}$start_port-$end_port${NC}"
    echo -e "Tipo: ${GREEN}$scan_type${NC}"
    echo ""
    
    open_ports=()
    total_ports=$((end_port - start_port + 1))
    current_port=0
    
    for (( port=$start_port; port<=$end_port; port++ )); do
        ((current_port++))
        echo -ne "Escaneando puerto $port/$end_port...\r"
        
        if check_tcp_port "$target_ip" "$port"; then
            echo -e "Puerto ${GREEN}$port${NC} está ${GREEN}abierto${NC}"
            open_ports+=($port)
        fi
    done
    
    echo -e "\n${YELLOW}Resumen del escaneo:${NC}"
    echo -e "Puertos escaneados: $total_ports"
    echo -e "Puertos abiertos encontrados: ${#open_ports[@]}"
    
    if [ ${#open_ports[@]} -gt 0 ]; then
        echo -e "Lista de puertos abiertos: ${GREEN}${open_ports[@]}${NC}"
        
        if $ping_on_open; then
            echo -e "\n${YELLOW}Realizando ping a la red $target_ip/$ping_mask...${NC}"
            network=$(echo $target_ip | cut -d'.' -f1-3)
            for i in {1..254}; do
                ping_host="$network.$i"
                if [ "$ping_host" != "$target_ip" ]; then
                    if ping -n 1 -w 1 $ping_host >/dev/null 2>&1; then
                        echo -e "Host ${GREEN}$ping_host${NC} está activo"
                    fi
                fi
            done
        fi
    fi
    
    if [[ -n "$output_file" ]]; then
        echo -e "\nGuardando resultados en $output_file..."
        {
            echo "Resultados del escaneo de puertos"
            echo "Fecha: $(date)"
            echo "Objetivo: $target_ip"
            echo "Rango de puertos: $start_port-$end_port"
            echo "Tipo de escaneo: $scan_type"
            echo ""
            echo "Puertos abiertos: ${open_ports[@]}"
            echo ""
            echo "Detalles:"
            for port in "${open_ports[@]}"; do
                echo "Puerto $port: abierto"
            done
        } > $output_file
        echo -e "${GREEN}Resultados guardados correctamente${NC}"
    fi
    
    echo -e "\nPresione Enter para continuar..."
    read
}

# Detección de Git Bash
if [[ "$OSTYPE" == "msys" ]]; then
    echo -e "${YELLOW}Se ha detectado Git Bash para Windows. Algunas funciones pueden ser limitadas.${NC}"
    sleep 2
fi

while true; do
    show_menu
    read option
    
    case $option in
        1) set_target;;
        2) set_port_range;;
        3) set_scan_type;;
        4) set_advanced_options;;
        5) run_scan;;
        6) show_config;;
        7) 
            echo -e "${BLUE}Saliendo del script...${NC}"
            exit 0;;
        *) 
            echo -e "${RED}Opción no válida${NC}"
            sleep 1;;
    esac
done