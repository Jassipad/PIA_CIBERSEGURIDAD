# helpp.py
import argparse

def help_parse():
    parser = argparse.ArgumentParser("""
    _______________________________________________________________________________________________
    Descripcion ganeral del programa: Este programa es un menu que realiza tareas de ciberseguridad
    _______________________________________________________________________________________________
    1. Buscar en Google para obtener listas de URLs: Realiza busquedas en internet con el argumento que le das y guarda las primeras 10 respuestas de busquedas en un archivo txt en la carpeta de salidas")
    2. Analizar URLs con VirusTotal: Realiza un Escaneo de URls maliciosas basandose en las URLs que se guardaron en el archivo da la opcion 1
    3. Analizar correos de las URLs: Extrae los correos que estan publicos en las URLs que se guardaron en elarchivo de la opcion 1
    4. Escaneo de puertos con Git-Bash: Escanea con bash los puertos de una IP especifica 
    5. Escaneo genaral de la red con Git-Bash: Hace tareas de escaneo con bash de la red de la cual estas conectado
    6. Ayuda: Es este mismo programa que estas utilizando para obtener un aayuda general del programa
    87 Salir: sale del programa princiapal                        
                                     """)
    
    parser.add_argument(
        "funcion",  # argumento posicional
        nargs='?',  # opcional (puede no venir)
        help="Nombre de la función para mostrar ayuda"
    )
    
    args = parser.parse_args()
    
    # Diccionario con info de cada función
    ayuda_funciones = {
        "buscar_en_google": "Busca en Google y obtiene listas de URLs.",
        "analizar_virustotal": "Analiza URLs usando VirusTotal API.",
        "analizar_correos": "Extrae y analiza correos electrónicos desde URLs.",
        "escaneo_puertos": "Lanza un escaneo de puertos usando Git-Bash.",
        "modulo_prueba": "Módulos de prueba A y B para tareas específicas."
    }
    
    
    if not args.funcion:
        return "Por favor, indique el nombre de la función para mostrar ayuda.\nFunciones disponibles: " + ", ".join(ayuda_funciones.keys())
    
    return ayuda_funciones.get(args.funcion, "Función no encontrada. Intente con: " + ", ".join(ayuda_funciones.keys()))
print(help_parse())
