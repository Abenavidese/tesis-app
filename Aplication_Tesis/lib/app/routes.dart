import 'package:flutter/material.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/menu/screens/main_menu_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String mainMenu = '/main-menu';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case mainMenu:
        return MaterialPageRoute(builder: (_) => const MainMenuScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}