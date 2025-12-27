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
    """
    doc = nlp(frase)
    candidatos = []

    for chunk in doc.noun_chunks:
        for token in chunk:
            if token.pos_ in ("NOUN", "PROPN") and not token.is_stop:
                lema = token.lemma_.lower()
                if lema not in GENERICOS:
                    candidatos.append((token.i, lema))

    if not candidatos:
        for token in doc:
            if token.pos_ in ("NOUN", "PROPN") and not token.is_stop:
                lema = token.lemma_.lower()
                if lema not in GENERICOS:
                    candidatos.append((token.i, lema))

    if not candidatos:
        return None

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
