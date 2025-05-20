import subprocess
from helpp import help_parse
import os
from modulo3 import sersh_mails
from modulo1 import buscar_en_google
from modulo2 import AnalizadorVirusTotal
import argparse
def mostrar_menu():
    """Muestra el menú principal con formato mejorado"""
    print("\n" + "═" * 50)
    print("SISTEMA DE ANÁLISIS DE SEGURIDAD".center(50))
    print("═" * 50)
    print("1. Buscar en Google para obtener listas de URLs")
    print("2. Analizar URLs con VirusTotal")
    print("3. Analizar correos de las URLs")
    print("4. Escaneo de puertos con Git-Bash")
    print("5. Esccaneo general de la red con Git-Bash")
    print("6. Help")
    print("7. Salir")
    return int(input("\nSeleccione una opción (1-7, solo el número): "))

def main():
    while True:
        try:
            op = mostrar_menu()
            
            if op == 1:
                consulta = input("Ingrese la búsqueda: ")
                try:
                    archivo = buscar_en_google(consulta)
                    print(f"Resultados guardados en: {archivo}")
                except Exception as e:
                    print(f"Ocurrió un error: {str(e)}")
            
            elif op == 2:
                directorio = 'salidas'
                if not os.path.exists(directorio):
                    print("No se encontró la carpeta 'salidas'.")
                    continue

                contenido = os.listdir(directorio)
                print("\n--- Archivos disponibles en 'salidas' ---")
                for item in contenido:
                    print(item)
                print("----------------------------------------")

                api_key = "b58061df516aa60065373c1b1eb171a136664566daf40bd7f5a94c010dedbbf8"
                analizador = AnalizadorVirusTotal(api_key)
                archivo_urls = input("Ingrese el nombre del archivo con URLs: ")
                archivo_urls = os.path.join("salidas", archivo_urls)

                try:
                    analizador.analizar_urls(archivo_urls)
                    print("Análisis completado.")
                except Exception as e:
                    print(f"Error al analizar con VirusTotal: {str(e)}")

            elif op == 3:
                directorio = 'salidas'
                if not os.path.exists(directorio):
                    print("No se encontró la carpeta 'salidas'.")
                    continue

                contenido = os.listdir(directorio)
                print("\n--- Archivos disponibles en 'salidas' ---")
                for item in contenido:
                    print(item)
                print("----------------------------------------")

                archivo_urls = input("Ingrese el nombre del archivo con URLs: ")
                archivo_urls = os.path.join("salidas", archivo_urls)
                try:
                    mail = sersh_mails(archivo_urls)
                    if mail:
                        print(f"Correos guardados en: {mail}")
                except Exception as e:
                    print(f"Error al analizar correos: {str(e)}")

            elif op == 4:
                try:
                    subprocess.Popen([
                        "C:\\Program Files\\Git\\git-bash.exe",
                        "-c", "./modulo4.sh"
                    ])
                    print("Script lanzado por separado.\n")
                except FileNotFoundError:
                    print("No se encontró Git Bash en la ruta especificada.")
            
            elif op == 5:
                script_path = "modulo5.sh"
                try:
                    comando = f'''
                    Start-Process "C:\\Program Files\\Git\\git-bash.exe" -ArgumentList '-c', "bash {script_path}" -Verb runAs
                    '''
                    subprocess.run(["powershell", "-Command", comando])
                except:
                    print("Por algun Motivo no se ejecuta el programa 5, solo escribe './modulo5.sh' en la terminal de bash")
            
            
            elif op == 6:
                
                print("Para Obtener ayuda Presione 7 para salir y escriba el sigiente comando en la terminal 'python helpp.py <comando> (ej. -h)'")

            
            elif op == 7:
                print("Cerrando el sistema...")
                break
            
            else:
                print("Opción inválida, por favor ingrese un número del 1 al 8.")
        
        except ValueError:
            print("Por favor, ingrese un número válido (1-8).")

if __name__ == "__main__":
    main()