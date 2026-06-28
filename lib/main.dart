import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/debt_provider.dart';
import 'screens/export_screen.dart';
import 'screens/home_screen.dart';
import 'screens/app_lock_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DebtBookApp());
}

class DebtBookApp extends StatelessWidget {
  const DebtBookApp({super.key});

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D6B8A),
      brightness: Brightness.light,
      primary: const Color(0xFF0D6B8A),
      secondary: const Color(0xFFF28C28),
      tertiary: const Color(0xFF2E9E5B),
      surface: const Color(0xFFFFFFFF),
    );

    final textTheme = GoogleFonts.manropeTextTheme().copyWith(
      headlineSmall: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.manrope(fontWeight: FontWeight.w500, height: 1.3),
      bodyMedium: GoogleFonts.manrope(fontWeight: FontWeight.w500, height: 1.3),
      labelLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: const Color(0x1A000000),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: Colors.white,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: const Color(0xFFFFD166),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => DebtProvider()..loadAllData()),
      ],
      child: MaterialApp(
        title: 'Debt Book',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        builder: (context, child) {
          final appSettings = context.watch<AppSettingsProvider>();
          if (appSettings.isLocked) {
            return const AppLockScreen();
          }
          return child ?? const SizedBox.shrink();
        },
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/export': (context) => const ExportScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
