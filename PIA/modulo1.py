import logging
from googlesearch import search
from datetime import datetime
import os

def configurar_log():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        filename='logs/busqueda.log',
        encoding='utf-8'
    )
    return logging.getLogger(__name__)

def buscar_en_google(consulta, num_resultados=10):
    logger = configurar_log()
    try:
        os.makedirs('salidas', exist_ok=True)
        os.makedirs('logs', exist_ok=True)

        logger.info(f"Iniciando búsqueda: {consulta}")
        resultados = list(search(
            term=consulta,
            num_results=num_resultados,
            lang='es',
            sleep_interval=2
        ))

        if not resultados:
            raise ValueError("No se encontraron resultados")

        archivo = f"salidas/resultados_{consulta}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        
        with open(archivo, 'w', encoding='utf-8') as f:
            for url in resultados:
                
                f.write(f"\n{url}")

        return archivo

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise