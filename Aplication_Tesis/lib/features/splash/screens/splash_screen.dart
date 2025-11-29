import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    
    // Bounce animation for loading dots
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Navigate after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }
  
  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            // Simple static background shapes
            _buildSimpleBackground(),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'BúhoSense',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 40 : 56,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF558B2F),
                      letterSpacing: 2,
                      fontFamily: 'Arial',
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  
                  // Owl GIF
                  Container(
                    width: isSmallScreen ? 180 : 256,
                    height: isSmallScreen ? 180 : 256,
                    child: Image.asset(
                      'assets/imagenes/buho.gif',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.flutter_dash,
                          size: isSmallScreen ? 90 : 128,
                          color: Color(0xFF558B2F),
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  
                  // Loading indicator
                  _buildLoadingDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSimpleBackground() {
    return Stack(
      children: [
        // Static circles - no animation
        Positioned(
          top: 40,
          left: 40,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Color(0xFF7CB342).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 60,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 80,
          right: 64,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFFFDD835).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 64,
          right: 100,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0xFFFDD835).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            final offset = math.sin((_bounceController.value * 2 * math.pi) + (index * math.pi / 3)) * 8;
            return Container(
              margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
              child: Transform.translate(
                offset: Offset(0, -offset.abs()),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(0xFF7CB342),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}