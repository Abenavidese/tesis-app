# test_esp32_serial.py - Prueba rápida de comunicación serial con ESP32
import serial
import time
import sys

def test_serial_connection(port, baudrate=115200):
    """
    Prueba la conexión serial con el ESP32
    """
    print(f"\n🔵 Test de Comunicación Serial ESP32")
    print(f"="*50)
    print(f"Puerto: {port}")
    print(f"Baudrate: {baudrate}")
    print(f"="*50)
    
    try:
        # Intentar abrir el puerto serial
        print(f"\n📡 Conectando a {port}...")
        ser = serial.Serial(port, baudrate, timeout=2)
        time.sleep(1)  # Esperar a que se establezca la conexión
        
        print(f"✅ Conexión establecida!")
        print(f"\n🧪 Enviando señal de prueba 't'...")
        
        # Enviar señal de prueba
        ser.write(b't')
        time.sleep(0.5)
        
        # Leer respuesta si hay
        if ser.in_waiting > 0:
            response = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
            print(f"📩 ESP32 respondió: {response}")
        else:
            print(f"⚠️ No hubo respuesta del ESP32 (esto es normal si no envía confirmación)")
        
        print(f"\n✅ Enviando señal 'b' (respuesta correcta)...")
        ser.write(b'b')
        time.sleep(1)
        
        # Leer respuesta si hay
        if ser.in_waiting > 0:
            response = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
            print(f"📩 ESP32 respondió: {response}")
        
        print(f"\n🎉 Test completado exitosamente!")
        print(f"💡 Verifica que el LED del ESP32 haya parpadeado")
        
        # Cerrar conexión
        ser.close()
        return True
        
    except serial.SerialException as e:
        print(f"\n❌ Error de comunicación serial:")
        print(f"   {str(e)}")
        print(f"\n💡 Soluciones:")
        print(f"   1. Verifica que el puerto {port} sea correcto")
        print(f"   2. Cierra el Serial Monitor de Arduino IDE")
        print(f"   3. Reconecta el ESP32 por Bluetooth")
        print(f"   4. Verifica en Administrador de Dispositivos")
        return False
        
    except Exception as e:
        print(f"\n❌ Error inesperado: {str(e)}")
        return False


def list_available_ports():
    """
    Lista todos los puertos COM disponibles
    """
    try:
        import serial.tools.list_ports
        
        print(f"\n📋 Puertos COM disponibles:")
        print(f"="*50)
        
        ports = serial.tools.list_ports.comports()
        
        if not ports:
            print("⚠️ No se encontraron puertos COM")
            return []
        
        for i, port in enumerate(ports, 1):
            print(f"{i}. {port.device} - {port.description}")
            if "Bluetooth" in port.description or "ESP32" in port.description:
                print(f"   👆 Este parece ser el ESP32!")
        
        print(f"="*50)
        return [port.device for port in ports]
        
    except ImportError:
        print("⚠️ pyserial no está instalado")
        print("Instala con: pip install pyserial")
        return []


if __name__ == "__main__":
    print("\n" + "="*50)
    print("  TEST DE COMUNICACIÓN SERIAL - ESP32")
    print("="*50)
    
    # Listar puertos disponibles
    available_ports = list_available_ports()
    
    # Determinar puerto a usar
    if len(sys.argv) > 1:
        # Puerto especificado por línea de comandos
        port = sys.argv[1]
        print(f"\n✅ Usando puerto especificado: {port}")
    elif available_ports:
        # Si hay puertos disponibles, preguntar
        print(f"\n🔍 Selecciona un puerto o presiona Enter para usar el primero:")
        try:
            choice = input(f"Puerto (default: {available_ports[0]}): ").strip()
            if choice:
                port = choice
            else:
                port = available_ports[0]
        except KeyboardInterrupt:
            print("\n\n❌ Cancelado por el usuario")
            sys.exit(0)
    else:
        print(f"\n❌ No se encontraron puertos COM disponibles")
        print(f"💡 Verifica que el ESP32 esté emparejado en Windows")
        sys.exit(1)
    
    # Ejecutar test
    success = test_serial_connection(port)
    
    if success:
        print(f"\n✅ Test exitoso!")
        print(f"\n📝 Para configurar el Gateway, usa:")
        print(f'   curl -X POST http://localhost:8001/configure_esp32 \\')
        print(f'     -H "Content-Type: application/json" \\')
        print(f'     -d \'{{"enabled": true, "port": "{port}", "baudrate": 115200}}\'')
    else:
        print(f"\n❌ Test fallido")
        print(f"\n💡 Verifica:")
        print(f"   1. ESP32 está encendido")
        print(f"   2. ESP32 está emparejado en Windows")
        print(f"   3. Código Bluetooth está cargado en el ESP32")
        print(f"   4. Serial Monitor de Arduino está cerrado")
    
    print()
