import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  
  // Secondary colors  
  static const Color secondary = Color(0xFF26C6DA);
  static const Color secondaryDark = Color(0xFF00ACC1);
  static const Color secondaryLight = Color(0xFF4DD0E1);
  
  // Accent colors
  static const Color accent = Color(0xFF9333EA);
  static const Color accentPink = Color(0xFFEC4899);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFe0f7fa),
      Color(0xFFb2ebf2),
      Color(0xFFffffff),
      Color(0xFFc8e6c9),
    ],
  );

  /// Paleta de fondo principal — variante clara. Azul-100 → verde-100,
  /// el patrón usado por todos los shells y pantallas con gradiente.
  static const List<Color> backgroundGradientLight = [
    Color(0xFFDBEAFE), // blue-100
    Color(0xFFD1FAE5), // green-100
  ];

  /// Variante oscura: slate-900 a teal-900 (mantiene el matiz azul→verde
  /// del modo claro pero con suficiente contraste para texto claro).
  static const List<Color> backgroundGradientDark = [
    Color(0xFF0F172A), // slate-900
    Color(0xFF134E4A), // teal-900
  ];

  /// Variante 3-stop usada por el shell de terapeuta.
  static const List<Color> backgroundGradient3Light = [
    Color(0xFFDBEAFE), // blue-100
    Color(0xFFF0FDF4), // green-50
    Color(0xFFEFF6FF), // blue-50
  ];

  static const List<Color> backgroundGradient3Dark = [
    Color(0xFF0F172A), // slate-900
    Color(0xFF134E4A), // teal-900
    Color(0xFF1E1B4B), // indigo-950
  ];
  
  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral colors - Light theme
  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  
  // Neutral colors - Dark theme
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
  
  // Social colors
  static const Color google = Color(0xFFDB4437);
  static const Color apple = Color(0xFF000000);
  static const Color facebook = Color(0xFF4267B2);
  
  // Link color
  static const Color link = Color(0xFF007AFF);
}
