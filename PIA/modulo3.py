import os
from datetime import datetime
from bs4 import BeautifulSoup  # Analizar HTML
import re                      # Buscar patrones como correos electrónicos
import requests                # Realizar solicitudes HTTP

def sersh_mails(archivo_urls):
    try:
        if not os.path.exists(archivo_urls):
            raise FileNotFoundError(f"Archivo no encontrado: {archivo_urls}")

        # Leer URLs
        with open(archivo_urls, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip()]
                
        if not urls:
            raise ValueError("El archivo no contiene URLs válidas")

    except Exception as e:
        print(f"Error: {str(e)}")
        return None

    # Crear archivo de salida con timestamp
    archivo_salida = f"salidas/mails_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"

    with open(archivo_salida, 'w', encoding='utf-8') as f:
        for url in urls:
            try:
                response = requests.get(url, timeout=10)  # Se recomienda establecer timeout
                html_content = response.text

                print(f"\nCorreos electrónicos encontrados en: {url}")
                emails = re.findall(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", html_content)

                for email in emails:
                    f.write(f"{email}\n")  # Es mejor sin salto inicial
                    print(email)

            except requests.RequestException as req_err:
                print(f"No se pudo acceder a {url}: {req_err}")

    return archivo_salida