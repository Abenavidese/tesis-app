#!/usr/bin/env python3
"""
Script para obtener todas las IPs disponibles para configurar Flutter
"""
import socket
import subprocess
import sys
import platform

def get_local_ips():
    """Obtiene todas las IPs locales disponibles"""
    ips = []
    
    try:
        # Obtener  princal
        hostname = socket.gethostname()
        local_ = socket.gethostbyname(hostname)
        ips.append(f"IP Principal: {local_ip}")
        
        # Obtener todas las interfaces de red
        if platform.system() == "Windows":
            result = subprocess.run(['ipconfig'], capture_output=True, text=True)
            lines = result.stdout.split('\n')
            for line in lines:
                if 'IPv4' in line and '192.168' in line:
                    ip = line.split(':')[1].strip()
                    if ip not in [item.split(': ')[1] for item in ips]:
                        ips.append(f"IP WiFi: {ip}")
        else:
            # Para Linux/Mac
            result = subprocess.run(['ifconfig'], capture_output=True, text=True)
            # Parsear ifconfig output...
            
    except Exception as e:
        print(f"Error obteniendo IPs: {e}")
    
    return ips

def print_flutter_config():
    """Imprime las configuraciones para Flutter"""
    print("🔍 Detectando IPs disponibles...\n")
    
    ips = get_local_ips()
    
    print("📍 IPs Encontradas:")
    for ip in ips:
        print(f"   {ip}")
    
    print("\n🏗️ Configuraciones para Flutter:")
    print("=" * 50)
    
    print("\n1️⃣ EMULADOR ANDROID:")
    print("   URL: http://10.0.2.2:8000")
    print("   Uso: Cuando corres en emulador Android")
    
    print("\n2️⃣ WEB/DESKTOP:")
    print("   URL: http://127.0.0.1:8000")
    print("   Uso: Cuando corres flutter web o desktop")
    
    print("\n3️⃣ SIMULADOR iOS:")
    print("   URL: http://localhost:8000")
    print("   Uso: Cuando corres en simulador iOS")
    
    if ips:
        for ip_info in ips:
            if "192.168" in ip_info or "10." in ip_info:
                ip = ip_info.split(': ')[1]
                print(f"\n4️⃣ DISPOSITIVO FÍSICO:")
                print(f"   URL: http://{ip}:8000")
                print("   Uso: Cuando corres en dispositivo real (mismo WiFi)")
                break
    
    print("\n" + "=" * 50)
    print("📝 INSTRUCCIONES:")
    print("1. Identifica dónde estás corriendo Flutter")
    print("2. Usa la URL correspondiente en ApiConstants.dart")
    print("3. Usa el botón 'Debug API' en la app para probar")
    
    print("\n🚀 Tu servidor está corriendo en:")
    print("   http://127.0.0.1:8000")

if __name__ == "__main__":
    print("🌐 Configurador de IPs para Flutter")
    print_flutter_config()