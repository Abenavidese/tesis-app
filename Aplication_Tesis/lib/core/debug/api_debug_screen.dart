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
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _testUrl(String url) async {
    setState(() {
      _isLoading = true;
      _testResult = 'Probando $url...';
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _testResult = '✅ CONECTADO!\n\nRespuesta:\n${data['message']}\n\nUsa esta URL: $url';
        });
      } else {
        setState(() {
          _testResult = '⚠️ Respuesta: ${response.statusCode}\n$url';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Error: $e\n$url';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API'),
        backgroundColor: Colors.red[700],
      ),
      body: Padding(
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
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResult.isEmpty ? 'Presiona un botón para probar la conexión...' : _testResult,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}