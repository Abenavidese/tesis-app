import os
import pandas as pd
from tqdm import tqdm

# 📁 Ruta raíz del dataset (nivel más alto)
root_dir = r"C:\Users\EleXc\Music\TESIS\TESTING"

# 📄 CSV de salida (puede ser en la misma carpeta del script)
output_csv_path = "captions.csv"

# Si output_csv_path incluye carpeta, créala. Si no, no hagas nada.
out_dir = os.path.dirname(output_csv_path)
if out_dir:
    os.makedirs(out_dir, exist_ok=True)

IMG_EXTS = (".jpg", ".jpeg", ".png")
csv_data = []

# 🔁 Recorrido recursivo
all_files = []
for dirpath, dirnames, filenames in os.walk(root_dir):
    for fn in filenames:
        all_files.append((dirpath, fn))

for dirpath, fn in tqdm(all_files, desc="Buscando imágenes"):
    if not fn.lower().endswith(IMG_EXTS):
        continue

    img_path = os.path.join(dirpath, fn)

    base = os.path.splitext(fn)[0]
    txt_path = os.path.join(dirpath, base + ".txt")

    if not os.path.exists(txt_path):
        print(f"⚠️ Falta TXT: {os.path.relpath(img_path, root_dir)}")
        continue

    with open(txt_path, "r", encoding="utf-8") as f:
        caption = f.read().strip()

    rel_img = os.path.relpath(img_path, root_dir)
    csv_data.append((rel_img, caption))

df = pd.DataFrame(csv_data, columns=["image", "caption"])
df.to_csv(output_csv_path, index=False, encoding="utf-8")

print(f"✅ CSV generado: {output_csv_path}")
print(f"✅ Filas: {len(df)}")
