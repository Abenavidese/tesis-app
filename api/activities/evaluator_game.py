from sentence_transformers import SentenceTransformer, util
import spacy
import os

# Forzar uso de CPU si hay incompatibilidad CUDA
os.environ['CUDA_VISIBLE_DEVICES'] = ''

nlp = spacy.load("es_core_news_sm")

model = SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2", device='cpu')

GENERICOS = {
    "animal", "cosa", "ser", "objeto", "elemento", "lugar",
    "imagen", "foto", "fotografía", "dibujo", "figura", "ilustración", "gráfico"
}

# Palabras de categoría/contexto que deben ignorarse (suelen aparecer al inicio)
CATEGORIAS_IGNORAR = {
    # Categorías generales
    "animales", "animal", "salvajes", "salvaje", "doméstico", "doméstica",
    "accidente", "accidentes", "geográfico", "geográfica",
    "ciclo", "vida", "etapa", "etapas",
    "esquema",
    "derecho", "derechos", 'ganado',
    "evento", "eventos", "familiar", "familiares",
    "edificio", "edificios", "histórico", "histórica",
    
    # Verbos y gerundios comunes
    "ayudar", "cuidar", "regar", "sacar", "hacer",
    
    # Lugares genéricos
    "hábitat", "entorno", "ambiente", "espacio",
    
    # Palabras de enlace
    "aquí", "allí", "este", "esta", "estos", "estas",
    
    # Palabras cuantitativas genéricas (priorizar sobre animales/objetos específicos)
    "variedad", "tipo", "tipos", "clase", "clases", "grupo", "grupos",
}

# Sistemas del cuerpo humano que deben detectarse completos
SISTEMAS_CUERPO = {
    "circulatorio", "digestivo", "locomotor", "respiratorio", 
    "nervioso", "muscular", "óseo", "excretor", "reproductor"
}

# Lista de animales que deben priorizarse como sujetos
ANIMALES_PRIORITARIOS = {
    "león", "tigre", "elefante", "jirafa", "cebra", "mono", "gorila",
    "vaca", "caballo", "cerdo", "oveja", "gallina", "gallo", "pato",
    "perro", "gato", "conejo", "ratón", "pájaro", "ave",
    "mariposa", "abeja", "hormiga", "araña", "mosca",
    "rana", "sapo", "serpiente", "cocodrilo", "tortuga",
    "pez", "tiburón", "ballena", "delfín", "pulpo",
    "burro", "cabra", "toro", "yegua", "pollo"
}


def similitud_semantica(texto1: str, texto2: str) -> float:
    """
    Calcula la similitud semántica entre dos textos usando Sentence Transformers.
    Devuelve un valor aproximado entre 0 y 1.
    """
    emb1 = model.encode(texto1, convert_to_tensor=True, device='cpu')
    emb2 = model.encode(texto2, convert_to_tensor=True, device='cpu')
    return util.cos_sim(emb1, emb2).item()


def obtener_sujeto(frase: str):
    """
    Obtiene el sujeto SEMÁNTICO de la frase:
    el sustantivo importante (burro, avión, río, montaña, etc.).
    No se usa el sujeto gramatical (yo, tú, él).
    
    Mejoras:
    - Ignora categorías genéricas ("Animales salvajes:", "Accidente geográfico:")
    - Para sistemas del cuerpo, usa "sistema X" completo
    - Prioriza sustantivos después de ":" si existe
    - Busca el sustantivo más específico, no el primero
    """
    # Si la frase tiene ":", verificar si es un sistema del cuerpo
    if ":" in frase:
        partes = frase.split(":", 1)
        prefijo = partes[0].strip().lower()
        
        # Verificar si el prefijo contiene "sistema" + nombre de sistema
        for sistema in SISTEMAS_CUERPO:
            if sistema in prefijo:
                # Devolver "sistema circulatorio", "sistema digestivo", etc.
                return f"sistema {sistema}"
        
        # Si no es un sistema pero hay contenido después del ":", procesar esa parte
        if len(partes) > 1:
            frase_principal = partes[1].strip()
            sujeto_principal = _extraer_sujeto_de_texto(frase_principal)
            if sujeto_principal:
                return sujeto_principal
    
    # Si no hay ":" o no se encontró sujeto después, procesar toda la frase
    return _extraer_sujeto_de_texto(frase)


def _extraer_sujeto_de_texto(texto: str):
    """
    Extrae el sujeto de un texto, ignorando categorías genéricas.
    Prioriza animales sobre sustantivos cuantitativos (variedad, tipo, etc.).
    """
    doc = nlp(texto)
    candidatos = []
    animales_encontrados = []

    # Buscar en noun_chunks primero (más preciso)
    for chunk in doc.noun_chunks:
        for token in chunk:
            if token.pos_ in ("NOUN", "PROPN") and not token.is_stop:
                lema = token.lemma_.lower()
                # Ignorar genéricos y categorías
                if lema not in GENERICOS and lema not in CATEGORIAS_IGNORAR:
                    candidatos.append((token.i, lema))
                    # Si es un animal prioritario, guardarlo
                    if lema in ANIMALES_PRIORITARIOS:
                        animales_encontrados.append((token.i, lema))

    # Si no hay candidatos, buscar en todos los tokens
    if not candidatos:
        for token in doc:
            if token.pos_ in ("NOUN", "PROPN") and not token.is_stop:
                lema = token.lemma_.lower()
                if lema not in GENERICOS and lema not in CATEGORIAS_IGNORAR:
                    candidatos.append((token.i, lema))
                    if lema in ANIMALES_PRIORITARIOS:
                        animales_encontrados.append((token.i, lema))

    if not candidatos:
        return None

    # PRIORIDAD 1: Si hay animales, devolver el primero
    if animales_encontrados:
        animales_encontrados.sort(key=lambda x: x[0])
        return animales_encontrados[0][1]
    
    # PRIORIDAD 2: Devolver el primer candidato general
    candidatos.sort(key=lambda x: x[0])
    return candidatos[0][1]


def evaluar_respuesta(texto_modelo: str, texto_nino: str, umbral: float = 0.6):
    """
    Evalúa la respuesta del niño comparándola con el texto del modelo.

    Flujo:
      1. Se obtiene el sujeto SEMÁNTICO de cada texto.
      2. Si los sujetos son distintos (o falta alguno), la respuesta es incorrecta.
      3. Si los sujetos son iguales, se calcula la similitud semántica.
      4. Si la similitud >= umbral, se considera correcta.
    """

    sujeto_modelo = obtener_sujeto(texto_modelo)
    sujeto_nino = obtener_sujeto(texto_nino)

    sujeto_igual = (
        sujeto_modelo is not None
        and sujeto_nino is not None
        and sujeto_modelo == sujeto_nino
    )

    if not sujeto_igual:
        return {
            "texto_modelo": texto_modelo,
            "texto_nino": texto_nino,
            "sujeto_modelo": sujeto_modelo,
            "sujeto_nino": sujeto_nino,
            "sujeto_igual": False,
            "similitud": 0.0,
            "umbral": umbral,
            "es_correcta": False,
        }

    sim = similitud_semantica(texto_modelo, texto_nino)
    es_correcta = sim >= umbral

    return {
        "texto_modelo": texto_modelo,
        "texto_nino": texto_nino,
        "sujeto_modelo": sujeto_modelo,
        "sujeto_nino": sujeto_nino,
        "sujeto_igual": True,
        "similitud": sim,
        "umbral": umbral,
        "es_correcta": es_correcta,
    }
