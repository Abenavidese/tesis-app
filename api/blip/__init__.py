"""
Módulo BLIP para generación de captions
"""
from .generation import BlipGenerator, quick_generate, get_global_generator

__all__ = ['BlipGenerator', 'quick_generate', 'get_global_generator']