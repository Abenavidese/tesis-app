"""
Diccionario personalizado de palabras en español para corrección ortográfica.
Este diccionario incluye palabras comunes con tildes, eñes y variantes.
"""

# Diccionario de correcciones comunes (palabra sin tilde -> palabra correcta)
CORRECCIONES_COMUNES = {
    # Artículos y pronombres
    "mi": "mí",
    "tu": "tú",
    "el": "él",
    "si": "sí",
    "te": "té",
    "se": "sé",
    # "de": "dé",  # Comentado: casi siempre es preposición, no verbo
    "mas": "más",
    "solo": "sólo",
    
    # Verbos comunes
    "esta": "está",
    "estas": "estás",
    "estan": "están",
    "cepillandose": "cepillándose",
    "lavandose": "lavándose",
    "peinandose": "peinándose",
    "esta": "ésta",
    "este": "éste",
    "estos": "éstos",
    "estas": "éstas",
    
    # Palabras con ñ
    "nino": "niño",
    "nina": "niña",
    "ninos": "niños",
    "ninas": "niñas",
    "anos": "años",
    "espanol": "español",
    "espanola": "española",
    "espanoles": "españoles",
    "espanolas": "españolas",
    "manana": "mañana",
    "montana": "montaña",
    "montanas": "montañas",
    "sueno": "sueño",
    "suenos": "sueños",
    "pequeno": "pequeño",
    "pequena": "pequeña",
    "pequenos": "pequeños",
    "pequenas": "pequeñas",
    "bano": "baño",
    "banos": "baños",
    
    # Interrogativos y exclamativos
    "que": "qué",
    "quien": "quién",
    "quienes": "quiénes",
    "cual": "cuál",
    "cuales": "cuáles",
    "cuando": "cuándo",
    "cuanto": "cuánto",
    "cuanta": "cuánta",
    "cuantos": "cuántos",
    "cuantas": "cuántas",
    "donde": "dónde",
    "como": "cómo",
    
    # Palabras comunes con tilde
    "acion": "acción",
    "alimentacion": "alimentación",
    "atencion": "atención",
    "aqui": "aquí",
    "alla": "allá",
    "arbol": "árbol",
    "arboles": "árboles",
    "asi": "así",
    "basica": "básica",
    "basico": "básico",
    "cafe": "café",
    "camion": "camión",
    "camara": "cámara",
    "caracteristico": "característico",
    "caracteristica": "característica",
    "climaticos": "climáticos",
    "climatico": "climático",
    "cria": "cría",
    "crias": "crías",
    "crisalida": "crisálida",
    "despues": "después",
    "dificil": "difícil",
    "dioxido": "dióxido",
    "educacion": "educación",
    "energias": "energías",
    "esofago": "esófago",
    "estomago": "estómago",
    "facil": "fácil",
    "geografico": "geográfico",
    "geografica": "geográfica",
    "geologicos": "geológicos",
    "geologico": "geológico",
    "gotica": "gótica",
    "gotico": "gótico",
    "historico": "histórico",
    "historica": "histórica",
    "jabon": "jabón",
    "jardin": "jardín",
    "jovenes": "jóvenes",
    "lapiz": "lápiz",
    "mama": "mamá",
    "medica": "médica",
    "medico": "médico",
    "movil": "móvil",
    "musica": "música",
    "nacion": "nación",
    "oxigeno": "oxígeno",
    "pajaro": "pájaro",
    "pajaros": "pájaros",
    "razon": "razón",
    "region": "región",
    "tambien": "también",
    "telefono": "teléfono",
    "television": "televisión",
    "ultimo": "último",
    "ultima": "última",
    "ultimos": "últimos",
    "ultimas": "últimas",
    
    # Colores y objetos comunes
    "azul": "azul",
    "blanco": "blanco",
    "blanca": "blanca",
    "negro": "negro",
    "negra": "negra",
    "rojo": "rojo",
    "roja": "roja",
    "verde": "verde",
    "amarillo": "amarillo",
    "amarilla": "amarilla",
    "basílica": "basílica",
    
    # Lugares
    "habitacion": "habitación",
    "cocina": "cocina",
    "salon": "salón",
    "comedor": "comedor",
    "dormitorio": "dormitorio",
    
    #agilidad": "agilidad",
    "atencion": "atención",
    "camilla": "camilla",
    "croquetas": "croquetas",
    "esquema": "esquema",
    "ingredientes": "ingredientes",
    "nutrientes": "nutrientes",
    "Objetos comunes en imágenes"
    "persona": "persona",
    "personas": "personas",
    "hombre": "hombre",
    "mujer": "mujer",
    "perro": "perro",
    "gato": "gato",
    "mesa": "mesa",
    "silla": "silla",
    "ventana": "ventana",
    "puerta": "puerta",
    "coche": "coche",
    "casa": "casa",
    "edificio": "edificio",
    "calle": "calle",
    "agua": "agua",
    "playa": "playa",
    "cielo": "cielo",
}

# Palabras que NO deben corregirse (contextuales)
PALABRAS_CONTEXTUALES = {
    "esta", "este", "estos", "estas",  # Pueden ser demostrativos o verbo estar
    "solo",  # Puede ser adjetivo o adverbio (casi siempre preposiciones/artículos)
    "de", "te", "se", "mi", "tu", "si",  # Dependen del contexto
}

# Vocabulario extendido en español (palabras correctas que el corrector debe conocer)
VOCABULARIO_ESPANOL = {
    # Ya incluye tildes y eñes
    "acción", "árbol", "árboles", "año", "años", "azul", "baño", "baños",
    "blanco", "blanca", "blancos", "blancas", "café", "calle", "cámara",
    "camión", "casa", "cielo", "cocina", "coche", "comedor", "dónde",
    "dormitorio", "edificio", "español", "española", "españoles", "españolas",
    "fácil", "difícil", "gato", "habitación", "hombre", "jardín",
    "lápiz", "mesa", "montaña", "montañas", "mujer", "música", "nación",
    "negro", "negra", "negros", "negras", "niño", "niña", "niños", "niñas",
    "pájaro", "pájaros", "pequeño", "pequeña", "pequeños", "pequeñas",
    "perro", "persona", "personas", "playa", "puerta", "razón", "rojo",
    "roja", "rojos", "rojas", "salón", "silla", "sueño", "sueños",
    "también", "teléfono", "televisión", "último", "última", "últimos",
    "últimas", "ventana", "verde", "verdes",
}

def obtener_correcciones():
    """Retorna el diccionario de correcciones comunes"""
    return CORRECCIONES_COMUNES

def obtener_vocabulario():
    """Retorna el vocabulario en español"""
    return VOCABULARIO_ESPANOL

def es_palabra_contextual(palabra):
    """Verifica si una palabra requiere contexto para ser corregida"""
    return palabra.lower() in PALABRAS_CONTEXTUALES
