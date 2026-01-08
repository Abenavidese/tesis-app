# characteristics_game.py - Juego de características para niños
"""
Módulo para el juego de características donde el niño debe identificar
las características de una imagen.

Formato esperado del modelo:
"isla, porción de tierra aislada, rodeada completamente por agua"
- Primera parte: nombre del objeto
- Resto: características separadas por comas
"""

from typing import List, Dict, Tuple
from sentence_transformers import SentenceTransformer, util
import re


# Modelo de similitud semántica (se carga una sola vez)
_similarity_model = None


def get_similarity_model():
    """Obtiene el modelo de similitud semántica (singleton)"""
    global _similarity_model
    if _similarity_model is None:
        print("⏳ Cargando modelo de similitud semántica...")
        _similarity_model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')
        print("✅ Modelo de similitud cargado")
    return _similarity_model


def parsear_caracteristicas(descripcion: str) -> Tuple[str, List[str]]:
    """
    Parsea la descripción del modelo para extraer nombre y características.
    
    Soporta dos formatos:
    1. Separado por comas: "nombre, característica1, característica2"
    2. Separado por guiones: "nombre: característica1 – característica2 – característica3"
    
    Args:
        descripcion: Descripción del modelo
    
    Returns:
        Tupla (nombre, lista_de_características)
    
    Ejemplos:
        >>> parsear_caracteristicas("isla, porción de tierra aislada, rodeada completamente por agua")
        ("isla", ["porción de tierra aislada", "rodeada completamente por agua"])
        
        >>> parsear_caracteristicas("Politécnica Salesiana: Excelencia académica – Innovación tecnológica – Formación en valores salesianos.")
        ("Politécnica Salesiana", ["Excelencia académica", "Innovación tecnológica", "Formación en valores salesianos"])
    """
    # Detectar formato: si tiene ":" y "–" es formato con guiones
    if ':' in descripcion and '–' in descripcion:
        # Formato: "nombre: característica1 – característica2 – característica3"
        partes = descripcion.split(':', 1)
        if len(partes) == 2:
            nombre = partes[0].strip()
            # Dividir características por guiones (–)
            caracteristicas_texto = partes[1].strip()
            # Eliminar punto final si existe
            caracteristicas_texto = caracteristicas_texto.rstrip('.')
            # Dividir por guiones (tanto – como -)
            caracteristicas = [c.strip() for c in re.split(r'[–-]', caracteristicas_texto) if c.strip()]
            return nombre, caracteristicas
        else:
            # Si no se puede parsear, intentar formato con comas
            pass
    
    # Formato por defecto: separado por comas
    partes = [parte.strip() for parte in descripcion.split(',')]
    
    if len(partes) < 2:
        # Si no hay suficientes partes, retornar la descripción completa como nombre
        return descripcion.strip(), []
    
    # Primera parte es el nombre
    nombre = partes[0]
    
    # Resto son características
    caracteristicas = partes[1:]
    
    return nombre, caracteristicas


def normalizar_texto(texto: str) -> str:
    """
    Normaliza texto para comparación.
    
    Args:
        texto: Texto a normalizar
    
    Returns:
        Texto normalizado (minúsculas, sin espacios extras, sin puntuación)
    """
    # Convertir a minúsculas
    texto = texto.lower().strip()
    
    # Eliminar puntuación al final
    texto = re.sub(r'[.,;:!?]+$', '', texto)
    
    # Normalizar espacios múltiples
    texto = re.sub(r'\s+', ' ', texto)
    
    return texto


def similitud_caracteristicas(carac1: str, carac2: str, umbral: float = 0.7) -> float:
    """
    Calcula la similitud semántica entre dos características.
    
    Args:
        carac1: Primera característica
        carac2: Segunda característica
        umbral: Umbral mínimo de similitud
    
    Returns:
        Score de similitud (0.0 a 1.0)
    """
    # Normalizar textos
    carac1_norm = normalizar_texto(carac1)
    carac2_norm = normalizar_texto(carac2)
    
    # Comparación exacta
    if carac1_norm == carac2_norm:
        return 1.0
    
    # Similitud semántica con modelo
    try:
        model = get_similarity_model()
        embeddings = model.encode([carac1_norm, carac2_norm], convert_to_tensor=True)
        similitud = util.cos_sim(embeddings[0], embeddings[1]).item()
        return similitud
    except Exception as e:
        print(f"⚠️ Error calculando similitud: {e}")
        # Fallback: comparación simple de palabras
        palabras1 = set(carac1_norm.split())
        palabras2 = set(carac2_norm.split())
        if not palabras1 or not palabras2:
            return 0.0
        interseccion = len(palabras1 & palabras2)
        union = len(palabras1 | palabras2)
        return interseccion / union if union > 0 else 0.0


def evaluar_caracteristicas(
    caracteristicas_modelo: List[str],
    caracteristicas_nino: List[str],
    umbral: float = 0.7
) -> Dict:
    """
    Evalúa si las características seleccionadas por el niño coinciden con las del modelo.
    
    Args:
        caracteristicas_modelo: Lista de características predichas por el modelo
        caracteristicas_nino: Lista de características seleccionadas por el niño
        umbral: Umbral de similitud para considerar una característica correcta
    
    Returns:
        Diccionario con:
        - es_correcto: True si la mayoría de características son correctas
        - caracteristicas_correctas: Lista de características correctas
        - caracteristicas_incorrectas: Lista de características incorrectas
        - porcentaje_acierto: Porcentaje de características correctas
        - detalles: Información detallada de cada característica
    """
    if not caracteristicas_nino:
        return {
            "es_correcto": False,
            "caracteristicas_correctas": [],
            "caracteristicas_incorrectas": [],
            "porcentaje_acierto": 0.0,
            "detalles": [],
            "mensaje": "No se seleccionaron características",
            "total_seleccionadas": 0,
            "total_correctas": 0
        }
    
    if not caracteristicas_modelo:
        return {
            "es_correcto": False,
            "caracteristicas_correctas": [],
            "caracteristicas_incorrectas": caracteristicas_nino,
            "porcentaje_acierto": 0.0,
            "detalles": [],
            "mensaje": "El modelo no generó características",
            "total_seleccionadas": len(caracteristicas_nino),
            "total_correctas": 0
        }
    
    caracteristicas_correctas = []
    caracteristicas_incorrectas = []
    detalles = []
    
    # Evaluar cada característica del niño
    for carac_nino in caracteristicas_nino:
        mejor_similitud = -1.0  # Inicializar con valor negativo para capturar incluso 0.0
        mejor_match = None
        
        # Buscar la característica del modelo más similar
        for carac_modelo in caracteristicas_modelo:
            similitud = similitud_caracteristicas(carac_nino, carac_modelo, umbral)
            if similitud > mejor_similitud:
                mejor_similitud = similitud
                mejor_match = carac_modelo
        
        # Si no se encontró ningún match (lista vacía), usar la primera característica
        if mejor_match is None and caracteristicas_modelo:
            mejor_match = caracteristicas_modelo[0]
            mejor_similitud = 0.0
        
        # Determinar si es correcta
        es_correcta = mejor_similitud >= umbral
        
        if es_correcta:
            caracteristicas_correctas.append(carac_nino)
        else:
            caracteristicas_incorrectas.append(carac_nino)
        
        detalles.append({
            "caracteristica_nino": carac_nino,
            "caracteristica_modelo_match": mejor_match,
            "similitud": round(mejor_similitud, 4),
            "es_correcta": es_correcta
        })
    
    # Calcular porcentaje de acierto
    total = len(caracteristicas_nino)
    correctas = len(caracteristicas_correctas)
    porcentaje = (correctas / total) * 100 if total > 0 else 0.0
    
    # Determinar si es correcto (al menos 60% de acierto)
    es_correcto = porcentaje >= 60.0
    
    # Generar mensaje
    if es_correcto:
        if porcentaje == 100.0:
            mensaje = "¡Perfecto! Todas las características son correctas 🎉"
        else:
            mensaje = f"¡Muy bien! {correctas}/{total} características correctas ✅"
    else:
        mensaje = f"¡Inténtalo de nuevo! Solo {correctas}/{total} características correctas"
    
    return {
        "es_correcto": es_correcto,
        "caracteristicas_correctas": caracteristicas_correctas,
        "caracteristicas_incorrectas": caracteristicas_incorrectas,
        "porcentaje_acierto": round(porcentaje, 2),
        "detalles": detalles,
        "mensaje": mensaje,
        "total_seleccionadas": total,
        "total_correctas": correctas
    }


def validar_juego_caracteristicas(
    descripcion_modelo: str,
    caracteristicas_nino: List[str],
    umbral: float = 0.7
) -> Dict:
    """
    Función principal para validar el juego de características.
    
    Args:
        descripcion_modelo: Descripción completa generada por el modelo
                           (formato: "nombre, característica1, característica2, ...")
        caracteristicas_nino: Lista de características seleccionadas por el niño
        umbral: Umbral de similitud para considerar una característica correcta
    
    Returns:
        Diccionario con el resultado de la evaluación
    """
    # Parsear la descripción del modelo
    nombre, caracteristicas_modelo = parsear_caracteristicas(descripcion_modelo)
    
    # Evaluar características
    resultado = evaluar_caracteristicas(
        caracteristicas_modelo=caracteristicas_modelo,
        caracteristicas_nino=caracteristicas_nino,
        umbral=umbral
    )
    
    # Agregar información adicional
    resultado["nombre_objeto"] = nombre
    resultado["caracteristicas_modelo"] = caracteristicas_modelo
    resultado["descripcion_completa"] = descripcion_modelo
    
    return resultado


# ============================================
# FUNCIONES DE TESTING
# ============================================

if __name__ == "__main__":
    # Test 1: Caso perfecto
    print("\n" + "="*60)
    print("TEST 1: Todas las características correctas")
    print("="*60)
    
    descripcion = "isla, porción de tierra aislada, rodeada completamente por agua"
    caracteristicas_nino = [
        "porción de tierra aislada",
        "rodeada completamente por agua"
    ]
    
    resultado = validar_juego_caracteristicas(descripcion, caracteristicas_nino)
    print(f"\nDescripción modelo: {descripcion}")
    print(f"Características niño: {caracteristicas_nino}")
    print(f"\nResultado: {resultado['mensaje']}")
    print(f"Es correcto: {resultado['es_correcto']}")
    print(f"Porcentaje: {resultado['porcentaje_acierto']}%")
    print(f"\nDetalles:")
    for detalle in resultado['detalles']:
        print(f"  - {detalle['caracteristica_nino']}: {'✅' if detalle['es_correcta'] else '❌'} (similitud: {detalle['similitud']})")
    
    # Test 2: Características similares pero no exactas
    print("\n" + "="*60)
    print("TEST 2: Características similares")
    print("="*60)
    
    caracteristicas_nino = [
        "tierra rodeada de agua",
        "aislada del continente"
    ]
    
    resultado = validar_juego_caracteristicas(descripcion, caracteristicas_nino)
    print(f"\nDescripción modelo: {descripcion}")
    print(f"Características niño: {caracteristicas_nino}")
    print(f"\nResultado: {resultado['mensaje']}")
    print(f"Es correcto: {resultado['es_correcto']}")
    print(f"Porcentaje: {resultado['porcentaje_acierto']}%")
    print(f"\nDetalles:")
    for detalle in resultado['detalles']:
        print(f"  - {detalle['caracteristica_nino']}: {'✅' if detalle['es_correcta'] else '❌'} (similitud: {detalle['similitud']})")
    
    # Test 3: Características incorrectas
    print("\n" + "="*60)
    print("TEST 3: Características incorrectas")
    print("="*60)
    
    caracteristicas_nino = [
        "tiene montañas altas",
        "clima muy frío"
    ]
    
    resultado = validar_juego_caracteristicas(descripcion, caracteristicas_nino)
    print(f"\nDescripción modelo: {descripcion}")
    print(f"Características niño: {caracteristicas_nino}")
    print(f"\nResultado: {resultado['mensaje']}")
    print(f"Es correcto: {resultado['es_correcto']}")
    print(f"Porcentaje: {resultado['porcentaje_acierto']}%")
    print(f"\nDetalles:")
    for detalle in resultado['detalles']:
        print(f"  - {detalle['caracteristica_nino']}: {'✅' if detalle['es_correcta'] else '❌'} (similitud: {detalle['similitud']})")
