import requests
import json
import os
from datetime import datetime
import logging

def configurar_log():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        filename='logs/virustotal.log'
    )
    return logging.getLogger(__name__)

class AnalizadorVirusTotal:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://www.virustotal.com/api/v3/urls"
        self.headers = {
            "x-apikey": self.api_key,
            "Accept": "application/json"
        }
        self.logger = configurar_log()
        os.makedirs('salidas', exist_ok=True)

    def analizar_urls(self, archivo_urls):
        """Analiza URLs y devuelve archivo con resultados"""
        try:
            # Verificar archivo de entrada
            if not os.path.exists(archivo_urls):
                raise FileNotFoundError(f"Archivo no encontrado: {archivo_urls}")

            # Leer URLs
            with open(archivo_urls, 'r', encoding='utf-8') as f:
                urls = [line.strip() for line in f if line.strip()]
            
            if not urls:
                raise ValueError("El archivo no contiene URLs válidas")

            resultados = []
            for url in urls[:5]:  # Limitar a 5 URLs para prueba
                try:
                    # Paso 1: Enviar URL para análisis
                    response = requests.post(
                        self.base_url,
                        headers=self.headers,
                        data={"url": url}
                    )
                    response.raise_for_status()
                    
                    # Paso 2: Obtener reporte
                    analysis_id = response.json()['data']['id']
                    report_url = f"{self.base_url}/{analysis_id}"
                    report = requests.get(report_url, headers=self.headers).json()
                    
                    resultados.append({
                        "url": url,
                        "analisis": report
                    })
                    self.logger.info(f"URL analizada: {url}")
                
                except Exception as e:
                    self.logger.warning(f"Error analizando {url}: {str(e)}")
                    continue

            # Guardar resultados
            return self._guardar_resultados(resultados)

        except Exception as e:
            self.logger.error(f"Error en análisis: {str(e)}")
            raise

    def _guardar_resultados(self, resultados):
        """Guarda los resultados en formato JSON"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            archivo_salida = f"salidas_Virustotal/virustotal_{timestamp}.json"
            
            with open(archivo_salida, 'w', encoding='utf-8') as f:
                json.dump(resultados, f, indent=4)
            
            self.logger.info(f"Resultados guardados en {archivo_salida}")
            return archivo_salida
            
        except Exception as e:
            self.logger.error(f"Error guardando resultados: {str(e)}")
            raise