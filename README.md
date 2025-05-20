# PIA_CIBERSEGURIDAD


# 🛡️ Proyecto PIA: Sistema de Análisis de Seguridad Informática

## 📁 Estructura del Proyecto

El proyecto contiene múltiples módulos en Python y Bash diseñados para realizar tareas de análisis de seguridad. Se apoya en la API de VirusTotal, 
manejo de logs, y generación de reportes.

PIA_extracted/

  PIA/

    helpp.py

    main.py

    modulo1.py

    modulo2.py

    modulo3.py

    modulo4.sh

    modulo5.sh

    salidassh.txt

    pycache/

      helpp.cpython-39.pyc

      main.cpython-39.pyc

      modulo1.cpython-39.pyc

      modulo2.cpython-39.pyc

      modulo3.cpython-39.pyc

      pruebas.cpython-39.pyc

    logs/

      busqueda.log

      virustotal.log

    salidas/

    salidas_Virustotal/

## 🔍 Descripción de Archivos Principales

### Scripts Python
- `main.py`: Punto de entrada principal del sistema.
- `modulo1.py`, `modulo2.py`, `modulo3.py`: Módulos especializados en la búsqueda, análisis y recolección de información de seguridad.
- `helpp.py`: Módulo de funciones auxiliares comunes.
- `__pycache__/`: Archivos compilados automáticamente por Python.

### Scripts Bash
- `modulo4.sh`, `modulo5.sh`: Scripts de shell utilizados para escaneo del sistema o análisis complementario, cuyos resultados se almacenan en `salidassh.txt`.

### Carpetas
- `logs/`: Contiene archivos de registro como `busqueda.log` y `virustotal.log` para auditoría y depuración.
- `salidas/`: Carpeta prevista para almacenar los resultados de los análisis realizados.
- `salidas_Virustotal/`: Resultados del análisis con la API de VirusTotal.

### Otros Archivos
- `ReadMe.txt`: Documento informativo preliminar.
- `salidassh.txt`: Archivo de salida generado por los scripts `.sh`.

## 🛠️ Requisitos

- Python 3.9 o superior
- Bash (Linux, macOS o WSL en Windows)
- Clave de API de VirusTotal (guardar en variable de entorno o archivo de configuración)
- Recomendado: PowerShell para integración completa multiplataforma

## 🚀 Ejecución

1. Clona el repositorio y navega a la carpeta del proyecto.
2. Instala las dependencias necesarias (si aplica).
3. Ejecuta `main.py` como script principal:

bash
      python main.py
      Ejecuta los scripts Bash si estás en un entorno compatible:
      bash modulo4.sh
      bash modulo5.sh

Este proyecto incluye integración con la API de VirusTotal para:
  - Verificación de direcciones IP sospechosas
  - Análisis de URLs y reputación
  - Obtención de reportes de amenazas

Licencia: Proyecto académico desarrollado como parte del Proyecto Integrador de Aprendizaje. Para fines educativos solamente.
