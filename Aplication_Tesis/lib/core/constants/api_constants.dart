class ApiConstants {
  // URLs para diferentes entornos
  static const String _localhostUrl = 'http://127.0.0.1:8000';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000'; // ✅ CONFIRMADO QUE FUNCIONA
  static const String _iosSimulatorUrl = 'http://localhost:8000';
  
  // URL principal - CONFIGURADA CORRECTAMENTE
  static const String baseUrl = _androidEmulatorUrl; // ✅ FUNCIONA con emulador Android
  static const String predictEndpoint = '/predict';
  
  // Timeout configurations
  static const int connectionTimeout = 60000; // 60 seconds
  static const int receiveTimeout = 180000; // 3 minutes (first model load takes time)
  
  // Supported image formats
  static const List<String> supportedImageTypes = [
    'image/png',
    'image/jpeg',
    'image/jpg'
  ];
  
  // URLs alternativas para probar
  static const List<String> alternativeUrls = [
    _androidEmulatorUrl,
    _localhostUrl,
    _iosSimulatorUrl,
    'http://172.16.223.111:8000', // Tu IP anterior
  ];
  
  // Comentarios sobre cuándo usar cada URL:
  // _androidEmulatorUrl: Para emulador Android
  // _localhostUrl: Para web o desktop
  // _iosSimulatorUrl: Para simulador iOS
  // IP real: Para dispositivo físico en la misma red
}