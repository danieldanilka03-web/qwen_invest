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
import 'theme/app_theme.dart';

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
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              home: const PortfoliosScreen(),
            );
          },
        );
      },
    );
  }
}
