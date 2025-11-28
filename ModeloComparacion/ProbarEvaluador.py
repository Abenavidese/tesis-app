from Evaluador import evaluar_respuesta

def main():
    texto_modelo = (
        "burros en su habitat domestico : estas imagenes muestran burros, "
        "su resistencia y comportamiento tranquilo, como interactuan con las personas "
        "y otros animales, y su papel en las actividades del entorno rural."
    )

    texto_nino = "estoy observando una imagen de un burro en su entorno natural."

    resultado = evaluar_respuesta(texto_modelo, texto_nino, umbral=0.6)

    print("=== RESULTADO DE LA EVALUACIÓN ===")
    print(f"Texto modelo : {resultado['texto_modelo']}")
    print(f"Texto niño   : {resultado['texto_nino']}")
    print(f"Sujeto modelo: {resultado['sujeto_modelo']}")
    print(f"Sujeto niño  : {resultado['sujeto_nino']}")
    print(f"Sujeto igual?: {resultado['sujeto_igual']}")
    print(f"Similitud    : {resultado['similitud']:.4f}")
    print(f"Umbral usado : {resultado['umbral']}")
    print(f"¿Es correcta?: {resultado['es_correcta']}")

if __name__ == "__main__":
    main()
