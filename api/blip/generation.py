from transformers import BlipProcessor, BlipForConditionalGeneration
from PIL import Image
import torch

class BlipGenerator:
    def __init__(self, model_path="blip-final-5", device="cpu", num_threads=4):
        self.device = torch.device(device)

        # Optimización CPU
        if self.device.type == "cpu":
            torch.set_num_threads(num_threads)
            torch.set_num_interop_threads(1)  # suele ayudar en ARM

        self.processor = BlipProcessor.from_pretrained(model_path)
        self.model = BlipForConditionalGeneration.from_pretrained(model_path).to(self.device)
        self.model.eval()

    @torch.inference_mode()
    def generate_caption(self, image: Image.Image) -> str:
        if image.mode != "RGB":
            image = image.convert("RGB")

        # (Opcional) Resize para bajar costo en Raspberry
        # image = image.resize((256, 256))

        inputs = self.processor(images=image, return_tensors="pt")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        out = self.model.generate(
            **inputs,
            max_new_tokens=100,     # 🔥 antes 1000
            num_beams=1,           # 🔥 antes 3
            do_sample=False,
            early_stopping=True,
        )
        return self.processor.decode(out[0], skip_special_tokens=True).strip()


_global_generator = None

def get_global_generator():
    global _global_generator
    if _global_generator is None:
        _global_generator = BlipGenerator(device="cpu", num_threads=4)
    return _global_generator

def quick_generate(image: Image.Image) -> str:
    return get_global_generator().generate_caption(image)
