"""
Script para analizar los sujetos detectados por el evaluador en todas las descripciones.

Este script:
1. Lee el CSV con las descripciones del modelo
2. Envía cada descripción al endpoint /evaluate
3. Extrae el sujeto_modelo detectado
4. Genera un CSV con: folder_name, content, sujeto_modelo
"""

import csv
import requests
import json
from pathlib import Path

# Configuración
API_URL = "http://localhost:8000/evaluate"
INPUT_CSV = "descripciones.csv"
OUTPUT_CSV = "analisis_sujetos.csv"

# Datos del CSV
csv_data = """folder_name,content
cepillandose,"Higiene: aquí se puede ver a un niño cepillándose los dientes frente al espejo, porque es importante mantener la limpieza bucal y cuidar la salud."
politecnica, "Politécnica Salesiana: Institución de educación superior que promueve la excelencia académica, la innovación tecnológica y los valores salesianos."
lavando_manos,"Higiene: aquí se puede ver a un niño lavándose las manos con agua y jabón en el lavabo, porque es importante mantener la limpieza para cuidar la salud."
peinandose,"Higiene: aquí se puede ver a un niño peinándose con cepillo frente al espejo, porque es importante mantener el cuidado personal y la limpieza."
circulatorio,"Sistema circulatorio: aquí se puede ver un esquema del sistema circulatorio, mostrando el corazón, arterias y venas, porque transporta sangre, oxígeno y nutrientes a todo el cuerpo."
digestivo,"Sistema digestivo: aquí se puede ver un esquema del sistema digestivo, mostrando boca, esófago, estómago e intestinos, porque permite descomponer los alimentos y absorber los nutrientes necesarios para el cuerpo."
locomotor,"Sistema locomotor: aquí se puede ver un esquema del sistema locomotor, mostrando huesos, articulaciones y músculos, porque permite el movimiento y sostiene el cuerpo humano."
respiratorio,"Sistema respiratorio: aquí se puede ver un esquema del sistema respiratorio, mostrando pulmones, tráquea y bronquios, porque permite la entrada de oxígeno y la salida de dióxido de carbono del cuerpo."
burro,"Burros en su hábitat doméstico: estas imágenes muestran burros, su resistencia y comportamiento tranquilo, cómo interactúan con las personas y otros animales, y su papel en las actividades del entorno rural."
caballo,"Caballo en su hábitat doméstico: estas imágenes muestran un caballo, su fuerza, elegancia y comportamiento en el entorno natural."
conejo,"Conejo en su hábitat natural: estas imágenes muestran un conejo, su comportamiento tranquilo y curioso, cómo interactúa con su entorno natural, y su adaptación al medio ambiente silvestre."
gallina,"Pollos de corral: estas imágenes muestran gallinas en una variedad de entornos, tanto en granjas como en prados. Las fotos capturan sus plumas de diferentes colores y su comportamiento en manada, destacando su naturaleza como aves de corral."
gato,"Gatos en su hábitat: estas imágenes muestran gatos de diferentes edades y colores, tanto dentro de un hogar como explorando al aire libre. Las fotos capturan su curiosidad, su elegancia y su comportamiento tranquilo y juguetón."
oveja,"Ovejas en su hábitat doméstico: estas imágenes muestran ovejas, su comportamiento en rebaños, cómo interactúan entre ellas, y su papel en el entorno rural, incluyendo la alimentación, el pastoreo y el cuidado diario."
perro,"Perros en su hábitat doméstico: estas imágenes muestran perros, destacando su comportamiento amistoso, su relación con las personas y su vida en el hogar."
vaca,"Vaca de granja: estas imágenes muestran una vaca en su hábitat, ya sea pastando en campos abiertos o interactuando con otras vacas. Las fotos capturan diferentes razas y edades, resaltando su vida en el campo y sus distintos comportamientos."
cebra,"Cebras en su hábitat natural: estas imágenes muestran cebras, resaltando su característico pelaje a rayas, su comportamiento en manada y su interacción con el entorno natural."
cocodrilo,"Cocodrilo en su hábitat natural: estas imágenes muestran cocodrilos, destacando su fuerza, su piel escamosa característica y su comportamiento en la naturaleza."
elefante,"Elefantes en su hábitat natural: estas imágenes muestran elefantes adultos y jóvenes, destacando su comportamiento social, su majestuosidad y su relación con la tierra y el agua en la naturaleza."
jirafa,"Jirafas en su entorno: estas imágenes muestran jirafas adultas y crías en su hábitat natural y en reservas, destacando su altura, elegancia, comportamiento social y el vínculo entre madre e cría."
leon,"León en su hábitat natural: aquí se puede ver un león de frente en su hábitat, rodeado de vegetación, ya que es un animal salvaje que vive en la naturaleza."
lobo,"Lobos en su hábitat natural: estas imágenes muestran lobos, destacando su comportamiento en manada, su agilidad y su vida en la naturaleza."
mono,"Monos en su hábitat natural: estas imágenes muestran monos, destacando su agilidad, interacción social y comportamiento en la naturaleza."
oso,"Osos grizzly en su hábitat natural: estas imágenes muestran osos grizzly, destacando su fuerza, tamaño imponente y comportamiento en la naturaleza."
tigre,"Tigre en su hábitat natural: aquí se puede ver un tigre de frente, un felino grande y fuerte, carnívoro, ya que es un animal salvaje que vive en la naturaleza."
mariposa,"Ciclo de vida de la mariposa: aquí se puede ver un esquema del ciclo de vida de la mariposa, mostrando huevo, oruga, crisálida y mariposa adulta, porque ilustra las etapas de crecimiento y metamorfosis de este insecto."
rana,"Ciclo de vida de la rana: aquí se puede ver un esquema del ciclo de vida de la rana, mostrando huevos, renacuajos y ranas adultas, porque ilustra las etapas de crecimiento y transformación de este anfibio."
desierto,"Accidente geográfico: aquí se puede ver un desierto con extensas dunas de arena y un cielo despejado, porque es una formación natural que refleja las condiciones climáticas y geográficas de la región."
glaciares,"Accidente geográfico: aquí se puede ver un glaciar, con sus enormes masas de hielo y nieve, porque es una formación natural que refleja los procesos geológicos y climáticos de la región."
isla,"Accidente geográfico: aquí se puede ver una isla rodeada de agua, con vegetación y playas, porque es una formación natural que forma parte del relieve y ecosistema de la región."
montana,"Accidente geográfico: aquí se puede ver montañas con picos elevados y laderas cubiertas de vegetación, porque son formaciones naturales que caracterizan el relieve y el paisaje de la región."
volcan,"Accidente geográfico: aquí se puede ver un volcán con su cima prominente y laderas rocosas, algunas con vegetación, porque es una formación natural que refleja la actividad geológica de la región."
basilica_quito,"Edificio histórico: aquí se puede ver la Basílica del Voto Nacional en Quito, con su arquitectura gótica imponente y detalles ornamentales, porque es un patrimonio histórico y cultural que refleja la historia y la identidad de la ciudad."
alimentacion,"Derecho a la alimentación: aquí se puede ver a una familia reunida alrededor de la mesa, compartiendo comida casera y sonriendo juntos, porque todo niño tiene derecho a una alimentación adecuada."
descanso,"Derecho al descanso: aquí se puede ver a un niño durmiendo tranquilamente en su cama, porque todo niño tiene derecho a descansar y recuperar energías"
educacion,"Derecho a la educación: aquí se puede ver a niños sentados en un aula con libros y cuadernos, escribiendo y escuchando a la maestra, porque todo niño tiene derecho a estudiar y aprender."
salud,"Derecho a la salud: aquí se puede ver a niños sentados en una camilla mientras un médico revisa su presión, acompañados de sus padres atentos y sonrientes, porque todo niño tiene derecho a recibir atención médica."
vivienda,"Derecho a una vivienda digna: aquí se puede ver a una familia frente a su casa limpia y ordenada, sonrientes y orgullosos de su hogar, porque todo niño tiene derecho a vivir en un lugar seguro."
ayuda_cocina,"Ayudar en la cocina: aquí se puede ver a un niño ayudando a su mamá a mezclar ingredientes en un bol, siguiendo instrucciones mientras cocinan juntos, porque es responsabilidad de cada persona colaborar en las tareas del hogar."
cuidar_mascota,"Cuidar a la mascota: aquí se puede ver a un niño sirviendo croquetas y agua a su perro en el patio, acariciándolo con cariño antes de que coma, porque es responsabilidad de cada persona cuidar y proteger a los animales."
regar_plantas,"Regar las plantas: aquí se puede ver a una niña regando plantas y flores en el jardín de su casa, concentrada en cubrir toda la tierra con agua, porque es responsabilidad de cada persona cuidar el entorno y las plantas."
sacar_basura,"Sacar la basura: aquí se puede ver a un niño llevando una bolsa de basura al contenedor frente a la casa, con cuidado de no derramar nada y asegurándose de cerrarla bien, porque es responsabilidad de cada persona mantener limpio su hogar."
cumple,"Evento familiar: aquí se puede ver a una familia celebrando el cumpleaños de un niño, con pastel, globos y sonrisas, porque es un momento para compartir alegría y festejar juntos."
navidad,"Evento familiar: aquí se puede ver a una familia celebrando la Navidad con gorros navideños, reunida alrededor del árbol decorado y compartiendo regalos, porque es un momento para disfrutar juntos y fortalecer los lazos familiares."
"""

def analizar_sujetos():
    """
    Analiza todas las descripciones y extrae el sujeto detectado por el evaluador.
    """
    print("=" * 80)
    print("🔍 ANÁLISIS DE SUJETOS EN DESCRIPCIONES")
    print("=" * 80)
    print(f"\n📡 API: {API_URL}")
    print(f"📄 Procesando {len(csv_data.strip().splitlines()) - 1} descripciones...\n")

    
    # Parsear CSV
    lines = csv_data.strip().splitlines()
    reader = csv.DictReader(lines)
    
    # Preparar resultados
    resultados = []
    errores = []
    
    for idx, row in enumerate(reader, 1):
        folder = row['folder_name']
        content = row['content']
        
        print(f"[{idx}/44] {folder}...", end=" ")
        
        try:
            # Hacer petición al endpoint
            payload = {
                "texto_modelo": content,
                "texto_nino": content,  # Usar la misma para extraer el sujeto
                "umbral": 0.5
            }
            
            response = requests.post(API_URL, json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            sujeto_modelo = data.get('detalles', {}).get('sujeto_modelo', 'N/A')
            
            resultados.append({
                'folder_name': folder,
                'content': content,
                'sujeto_modelo': sujeto_modelo
            })
            
            print(f"✅ Sujeto: '{sujeto_modelo}'")
            
        except requests.exceptions.RequestException as e:
            error_msg = str(e)
            errores.append({
                'folder_name': folder,
                'error': error_msg
            })
            print(f"❌ Error: {error_msg}")
        except Exception as e:
            error_msg = str(e)
            errores.append({
                'folder_name': folder,
                'error': error_msg
            })
            print(f"❌ Error inesperado: {error_msg}")
    
    # Guardar resultados en CSV
    print("\n" + "=" * 80)
    print("💾 Guardando resultados...")
    
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['folder_name', 'content', 'sujeto_modelo'])
        writer.writeheader()
        writer.writerows(resultados)
    
    print(f"✅ Resultados guardados en: {OUTPUT_CSV}")
    
    # Mostrar estadísticas
    print("\n" + "=" * 80)
    print("📊 ESTADÍSTICAS")
    print("=" * 80)
    print(f"✅ Procesadas exitosamente: {len(resultados)}/44")
    print(f"❌ Errores: {len(errores)}/44")
    
    if errores:
        print("\n⚠️ Descripciones con error:")
        for error in errores:
            print(f"   - {error['folder_name']}: {error['error']}")
    
    # Análisis de sujetos detectados
    print("\n📋 SUJETOS DETECTADOS:")
    print("-" * 80)
    
    sujetos_unicos = {}
    sin_sujeto = []
    
    for r in resultados:
        sujeto = r['sujeto_modelo']
        folder = r['folder_name']
        
        if sujeto == 'N/A' or sujeto is None or sujeto == 'None':
            sin_sujeto.append(folder)
        else:
            if sujeto not in sujetos_unicos:
                sujetos_unicos[sujeto] = []
            sujetos_unicos[sujeto].append(folder)
    
    # Mostrar sujetos únicos
    print(f"\n🎯 Sujetos únicos detectados: {len(sujetos_unicos)}")
    for sujeto, folders in sorted(sujetos_unicos.items()):
        print(f"   '{sujeto}': {len(folders)} veces - {', '.join(folders[:3])}{'...' if len(folders) > 3 else ''}")
    
    # Mostrar descripciones sin sujeto
    if sin_sujeto:
        print(f"\n⚠️ Descripciones SIN sujeto detectado ({len(sin_sujeto)}):")
        for folder in sin_sujeto:
            # Buscar la descripción completa
            desc = next((r['content'] for r in resultados if r['folder_name'] == folder), '')
            print(f"   - {folder}")
            print(f"     \"{desc[:80]}...\"")
    else:
        print("\n✅ Todas las descripciones tienen sujeto detectado")
    
    print("\n" + "=" * 80)
    print("✅ ANÁLISIS COMPLETADO")
    print("=" * 80)
    print(f"\n📁 Revisa el archivo: {OUTPUT_CSV}")
    print("💡 Tip: Abre el CSV en Excel para ver los resultados")


if __name__ == "__main__":
    try:
        analizar_sujetos()
    except KeyboardInterrupt:
        print("\n\n⚠️ Proceso interrumpido por el usuario")
    except Exception as e:
        print(f"\n\n❌ Error fatal: {e}")
        import traceback
        traceback.print_exc()
