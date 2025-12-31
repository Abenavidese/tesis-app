import 'package:flutter/material.dart';
import '../../activities/activity1/screens/activity1_intro_screen.dart';
import '../../activities/activity2/screens/activity2_intro_screen.dart';
import '../../activities/activity3/screens/activity3_intro_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Stack(
          children: [
            // Decoraciones de fondo
            ..._buildBackgroundDecorations(),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  
                  // Header con búho
                  _buildHeader(),
                  
                  const SizedBox(height: 8),
                  
                  // Botones de actividades
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActivityButton(
                          context: context,
                          number: '1',
                          title: 'ACTIVIDAD 1',
                          subtitle: '¡Di lo que ves!',
                          icon: '📸',
                          colors: [const Color(0xFF7CB342), const Color(0xFF558B2F)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Activity1IntroScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        
                        _buildActivityButton(
                          context: context,
                          number: '2',
                          title: 'ACTIVIDAD 2',
                          subtitle: '¡Responde el quiz!',
                          icon: '🎯',
                          colors: [const Color(0xFF42A5F5), const Color(0xFF1976D2)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Activity2IntroScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        
                        _buildActivityButton(
                          context: context,
                          number: '3',
                          title: 'ACTIVIDAD 3',
                          subtitle: '¡Retos divertidos!',
                          icon: '🏆',
                          colors: [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Activity3IntroScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Botón de galería
                  _buildGalleryButton(context),
                  
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundDecorations() {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF7CB342).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -70,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 200,
        left: 20,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF558B2F).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/imagenes/owl-take-photo.png',
            width: 50,
            height: 50,
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Elige una actividad',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityButton({
    required BuildContext context,
    required String number,
    required String title,
    required String subtitle,
    required String icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Número
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icono
                Text(
                  icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Abrir galería
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Galería - Próximamente')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/imagenes/owl-load-file.png',
                  width: 35,
                  height: 35,
                ),
                const SizedBox(width: 12),
                const Text(
                  '📁 GALERÍA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
