"""
Módulo BLIP para generación de captions con corrección ortográfica integrada
"""
from .generation import BlipEspanol, quick_generate, get_global_generator

# Alias para compatibilidad (BlipGenerator ahora es BlipEspanol)
BlipGenerator = BlipEspanol

__all__ = ['BlipEspanol', 'BlipGenerator', 'quick_generate', 'get_global_generator']