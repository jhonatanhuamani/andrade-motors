import 'package:flutter/material.dart';

class AppTheme {
  static const anchoContenido = 960.0;
  static const alerta = Color(0xFFE89870);
  static const radio = 22.0;
  static const oro = Color.fromARGB(255, 183, 142, 61);
  static const fondo = Color(0xFF0B0D0F);
  static const superficie = Color(0xFF15181C);
  static const elevado = Color(0xFF1B1E22);
  static const linea = Color(0xFF2C3037);
  static const texto = Color(0xFFF4F1EB);
  static const secundario = Color(0xFF969DA8);
  static const verde = Color.fromARGB(255, 16, 144, 69);
  static const LinearGradient gradienteOro = LinearGradient(
    colors: [Color(0xFFF0D6A2), oro, Color(0xFFAD8243)],
  );
  static ThemeData get oscuro => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: fondo,
    colorScheme: const ColorScheme.dark(
      primary: oro,
      onPrimary: Color(0xFF201A10),
      secondary: oro,
      surface: superficie,
      onSurface: texto,
      onSurfaceVariant: secundario,
      outline: linea,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.06,
        letterSpacing: -1.6,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -1,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
      ),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 15, height: 1.6),
      bodyMedium: TextStyle(fontSize: 13, height: 1.5),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ).apply(bodyColor: texto, displayColor: texto),
    appBarTheme: const AppBarTheme(
      backgroundColor: fondo,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 78,
      titleSpacing: 20,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF121519),
      hintStyle: const TextStyle(color: secundario, fontSize: 13),
      labelStyle: const TextStyle(color: secundario, fontSize: 13),
      prefixIconColor: oro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: linea),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: oro),
      ),
    ),
    cardTheme: CardThemeData(
      color: superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: linea),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: oro,
        foregroundColor: const Color(0xFF201A10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: texto,
        side: const BorderSide(color: linea),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: oro,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: superficie,
      selectedColor: oro,
      secondaryLabelStyle: const TextStyle(
        color: Color(0xFF201A10),
        fontWeight: FontWeight.w700,
      ),
      labelStyle: const TextStyle(fontSize: 12),
      side: const BorderSide(color: linea),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: linea, thickness: 1, space: 32),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: superficie,
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: elevado,
      contentTextStyle: const TextStyle(color: texto),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 78,
      backgroundColor: const Color(0xFF121519),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFF3D3424),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 10,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? oro : secundario,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected) ? oro : secundario,
        ),
      ),
    ),
  );
}
