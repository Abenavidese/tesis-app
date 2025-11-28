import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  String _currentUrl = ApiConstants.baseUrl;
  bool _isLoading = false;

  Future<void> _testUrl(String url) async {
    setState(() {
      _isLoading = true;
    });

    String title = '';
    String message = '';
    Color iconColor = Colors.grey;
    IconData icon = Icons.info;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        title = '✅ CONEXIÓN EXITOSA';
        message = 'Respuesta: ${data['message']}\n\nURL: $url';
        iconColor = Colors.green;
        icon = Icons.check_circle;
        
        setState(() {
          _currentUrl = url;
        });
      } else {
        title = '⚠️ RESPUESTA NO ESPERADA';
        message = 'Código: ${response.statusCode}\n\nURL: $url';
        iconColor = Colors.orange;
        icon = Icons.warning;
      }
    } catch (e) {
      title = '❌ ERROR DE CONEXIÓN';
      message = 'No se pudo conectar al servidor.\n\nError: ${e.toString()}\n\nURL: $url';
      iconColor = Colors.red;
      icon = Icons.error;
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar diálogo emergente
      if (mounted) {
        _showResultDialog(title, message, iconColor, icon);
      }
    }
  }

  void _showResultDialog(String title, String message, Color iconColor, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, color: iconColor),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API'),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prueba de Conectividad con Servidor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text('URLs Disponibles:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            
            ...ApiConstants.alternativeUrls.map((url) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _testUrl(url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentUrl == url ? Colors.green : null,
                  ),
                  child: Text(
                    url.replaceAll('http://', ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            )).toList(),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Guía:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• 10.0.2.2:8000 → Emulador Android'),
                  Text('• 127.0.0.1:8000 → Web/Desktop'),
                  Text('• localhost:8000 → iOS Simulator'),
                  Text('• IP real → Dispositivo físico'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'ℹ️ Los resultados aparecerán en una ventana emergente',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}