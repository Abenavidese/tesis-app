"""
Generador de quiz educativo basado en las descripciones del modelo BLIP.

Este módulo genera preguntas de opción múltiple usando el título de la descripción
como respuesta correcta y selecciona 3 distractores aleatorios de temas similares.
"""

import random

# Lista completa de temas/distractores posibles
TOPICS = [
    # Salud y cuidado personal
    "Higiene",
    "Cuidado personal",
    "Alimentación saludable",
    "Descanso y sueño",
    "Orden y limpieza",
    
    # Responsabilidades del hogar
    "Ayudar en casa",
    "Cuidar a la mascota",
    "Regar las plantas",
    "Reciclaje",
    "Cuidado del medio ambiente",
    "Uso responsable del agua",
    "Ahorro de energía",
    "Seguridad en el hogar",
    
    # Valores sociales
    "Familia",
    "Comunidad",
    "Amistad",
    "Respeto",
    "Solidaridad",
    "Trabajo en equipo",
    "Normas de convivencia",
    "Celebraciones familiares",
    "Tradiciones culturales",
    "Identidad cultural",
    
    # Derechos
    "Derecho a la educación",
    "Derecho a la salud",
    "Derecho a la alimentación",
    "Derecho al descanso",
    "Derecho a una vivienda digna",
    "Derecho a jugar",
    "Derecho a ser protegido",
    
    # Cuerpo humano
    "Sistema digestivo",
    "Sistema respiratorio",
    "Sistema circulatorio",
    "Sistema locomotor",
    "Partes del cuerpo humano",
    "Los sentidos",
    "Hábitos saludables",
    
    # Naturaleza
    "Animales domésticos",
    "Animales salvajes",
    "Plantas",
    "Ciclo de vida de los animales",
    "Ciclo de vida de las plantas",
    "Ecosistemas",
    "Cuidado de los animales",
    "Seres vivos y no vivos",
    
    # Geografía
    "Accidentes geográficos",
    "Montañas",
    "Ríos",
    "Islas",
    "Desiertos",
    "Volcanes",
    "Regiones del Ecuador",
    "El campo",
    "La ciudad",
    
    # Cultura
    "Edificios históricos",
    "Patrimonio cultural",
    "Símbolos patrios",
    "Fiestas tradicionales",
    "Personajes históricos",
    
    # Recreación
    "Juegos y recreación",
    "Deporte",
    "Actividades al aire libre",
    "Cumpleaños",
    "Navidad",
    "Eventos escolares",
    
    # Educación
    "La escuela",
    "El aula",
    "Estudiar y aprender",
    "Lectura",
    "Escritura"
]


def extraer_titulo(caption: str) -> str:
    """
    Extrae el título de una descripción.
    
    Ejemplo:
        Input: "Higiene: aquí se puede ver a un niño cepillándose..."
        Output: "Higiene"
    
    Args:
        caption: Caption completo del modelo
    
    Returns:
        str: Título extraído (antes del primer ':')
    """
    if ':' in caption:
        return caption.split(':', 1)[0].strip()
    return caption.strip()


def seleccionar_distractores(titulo_correcto: str, cantidad: int = 3) -> list:
    """
    Selecciona distractores aleatorios diferentes al título correcto.
    
    Args:
        titulo_correcto: El título correcto a excluir
        cantidad: Número de distractores a seleccionar (default: 3)
    
    Returns:
        list: Lista de distractores seleccionados
    """
    # Filtrar el título correcto de los posibles distractores
    distractores_disponibles = [t for t in TOPICS if t.lower() != titulo_correcto.lower()]
    
    # Si no hay suficientes distractores, usar todos los disponibles
    if len(distractores_disponibles) < cantidad:
        return distractores_disponibles
    
    # Seleccionar aleatoriamente
    return random.sample(distractores_disponibles, cantidad)


def generar_quiz(title_correct: str, caption: str) -> dict:
    """
    Genera una pregunta de quiz con opciones múltiples.
    
    Args:
        title_correct: Título correcto de la imagen
        caption: Caption completo generado por el modelo
    
    Returns:
        dict: {
            "question": "¿Cuál es el tema correcto de la imagen?",
            "caption": caption completo,
            "choices": lista de 4 opciones mezcladas,
            "answer": título correcto
        }
    """
    # Limpiar el título correcto
    titulo_limpio = title_correct.strip()
    
    # Seleccionar 3 distractores
    distractores = seleccionar_distractores(titulo_limpio, cantidad=3)
    
    # Crear lista de opciones (correcta + 3 incorrectas)
    choices = [titulo_limpio] + distractores
    
    # Mezclar las opciones aleatoriamente
    random.shuffle(choices)
    
    return {
        "question": "¿Cuál es el tema correcto de la imagen?",
        "caption": caption,
        "choices": choices,
        "answer": titulo_limpio
    }


def validar_respuesta_quiz(respuesta_usuario: str, respuesta_correcta: str) -> dict:
    """
    Valida si la respuesta del usuario es correcta.
    
    Args:
        respuesta_usuario: Opción seleccionada por el usuario
        respuesta_correcta: Respuesta correcta
    
    Returns:
        dict: {
            "es_correcta": bool,
            "respuesta_usuario": str,
            "respuesta_correcta": str,
            "mensaje": str
        }
    """
    es_correcta = respuesta_usuario.strip().lower() == respuesta_correcta.strip().lower()
    
    if es_correcta:
        mensaje = "¡Excelente! Tu respuesta es correcta."
    else:
        mensaje = f"¡Inténtalo de nuevo! La respuesta correcta era: {respuesta_correcta}"
    
    return {
        "es_correcta": es_correcta,
        "respuesta_usuario": respuesta_usuario,
        "respuesta_correcta": respuesta_correcta,
        "mensaje": mensaje
    }


# Para testing
if __name__ == "__main__":
    # Ejemplo de uso
    caption = "Higiene: aquí se puede ver a un niño cepillándose los dientes frente al espejo, porque es importante mantener la limpieza bucal y cuidar la salud."
    titulo = extraer_titulo(caption)
    
    print(f"Título extraído: {titulo}")
    print()
    
    quiz = generar_quiz(titulo, caption)
    print("Quiz generado:")
    print(f"Pregunta: {quiz['question']}")
    print(f"Opciones: {quiz['choices']}")
    print(f"Respuesta correcta: {quiz['answer']}")
