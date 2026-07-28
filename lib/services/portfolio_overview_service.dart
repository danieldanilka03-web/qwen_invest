import 'portfolio_service.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/purchase.dart';
import '../models/income.dart';

/// Сводные показатели одного портфеля — для экрана "Все портфели".
class PortfolioSummary {
  final PortfolioMeta meta;
  final double valueRub;
  final double profitRub;
  final int holdingsCount;

  const PortfolioSummary({
    required this.meta,
    required this.valueRub,
    required this.profitRub,
    required this.holdingsCount,
  });
}

/// Считает сводку по каждому портфелю сразу, не переключая активный —
/// для неактивных портфелей их данные читаются во временно открытых
/// (и сразу закрытых) боксах через StorageService.readDataFor.
class PortfolioOverviewService {
  static Future<List<PortfolioSummary>> allSummaries() async {
    final result = <PortfolioSummary>[];
    for (final meta in PortfolioService.list) {
      final data = await StorageService.readDataFor(meta.id);
      
      // Временно заменяем данные в StorageService для расчёта
      final originalPurchases = StorageService.purchases;
      final originalIncomes = StorageService.incomes;
      
      // Создаём временные боксы с данными нужного портфеля
      final tempPurchasesBox = await Hive.openBox<Purchase>('purchases_temp');
      final tempIncomesBox = await Hive.openBox<Income>('incomes_temp');
      
      // Очищаем и заполняем временные боксы
      await tempPurchasesBox.clear();
      await tempIncomesBox.clear();
      for (var i = 0; i < data.purchases.length; i++) {
        await tempPurchasesBox.put(i, data.purchases[i]);
      }
      for (var i = 0; i < data.incomes.length; i++) {
        await tempIncomesBox.put(i, data.incomes[i]);
      }
      
      // temporarily override the boxes
      final originalPurchasesBox = StorageService.purchasesBox;
      final originalIncomesBox = StorageService.incomesBox;
      StorageService.purchasesBox = tempPurchasesBox;
      StorageService.incomesBox = tempIncomesBox;
      
      try {
        final holdings = AnalyticsService.currentHoldings();
        final valueRub = holdings.values.fold(0.0, (s, h) => s + h.valueRub);
        final unrealized = holdings.values.fold(0.0, (s, h) => s + h.pnlRub);
        final realized = AnalyticsService.totalRealizedPnlRub();
        final income = AnalyticsService.totalIncome();
        result.add(PortfolioSummary(
          meta: meta,
          valueRub: valueRub,
          profitRub: unrealized + realized + income,
          holdingsCount: holdings.length,
        ));
      } finally {
        // Восстанавливаем оригинальные боксы
        StorageService.purchasesBox = originalPurchasesBox;
        StorageService.incomesBox = originalIncomesBox;
        await tempPurchasesBox.close();
        await tempIncomesBox.close();
      }
    }
    return result;
  }
}
