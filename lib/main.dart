import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/storage_service.dart';
import 'services/portfolio_service.dart';
import 'services/theme_service.dart';
import 'services/favorites_service.dart';
import 'services/currency_service.dart';
import 'services/tax_service.dart';
import 'services/sector_service.dart';
import 'services/manual_price_service.dart';
import 'services/logo_service.dart';
import 'services/backup_settings_service.dart';
import 'services/auto_backup_service.dart';
import 'screens/portfolios_screen.dart';

// Держим ссылку на верхнем уровне, чтобы слушатель жизненного цикла не был
// собран сборщиком мусора (AppLifecycleListener не привязан к дереву виджетов).
late final AppLifecycleListener _lifecycleListener;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  StorageService.registerAdapters();
  await PortfolioService.init(); // должен инициализироваться до StorageService/SectorService — они читают активный портфель
  await StorageService.init();
  await ThemeService.init();
  await FavoritesService.init();
  await CurrencyService.init();
  await TaxService.init();
  await SectorService.init();
  await ManualPriceService.init();
  await LogoService.init();
  await BackupSettingsService.init();
  AutoBackupService.attach();
  unawaited(AutoBackupService.runNowIfEnabled());

  // "Вход и выход из приложения" на Android/iOS обычно НЕ перезапускают
  // процесс (main() не вызывается заново) — это просто сворачивание/разворачивание,
  // поэтому одного запуска при старте недостаточно: без этого слушателя
  // автобэкап срабатывал только на настоящий холодный старт. resumed —
  // вернулись в приложение, paused/detached — свернули или закрыли.
  _lifecycleListener = AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.resumed ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        unawaited(AutoBackupService.runNowIfEnabled());
      }
    },
  );

  runApp(const InvestTrackerApp());
}

class InvestTrackerApp extends StatelessWidget {
  const InvestTrackerApp({super.key});

  ThemeData _buildTheme(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: isDark
          ? scheme.copyWith(
              surface: const Color(0xFF11141C),
              surfaceContainerLow: const Color(0xFF161A24),
              surfaceContainerHigh: const Color(0xFF1C212E),
            )
          : scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF07090D) : const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? Colors.transparent : null,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: isDark ? const Color(0xFF161A24) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : null,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        height: 64,
        backgroundColor: isDark ? const Color(0xFF0B0E14) : null,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
      textTheme: const TextTheme().apply(fontFamily: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: ThemeService.accentColor,
      builder: (context, accent, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeMode,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'Invest Tracker',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(accent, Brightness.light),
              darkTheme: _buildTheme(accent, Brightness.dark),
              themeMode: mode,
              home: const PortfoliosScreen(),
            );
          },
        );
      },
    );
  }
}
