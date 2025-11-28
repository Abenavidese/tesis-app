"""
Módulo BLIP para generación de captions
"""
from .generation import BlipGenerator, generate_caption_from_image, quick_generate, get_global_generator

__all__ = ['BlipGenerator', 'generate_caption_from_image', 'quick_generate', 'get_global_generator']