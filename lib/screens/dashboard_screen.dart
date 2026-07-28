import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../services/favorites_service.dart';
import '../services/tax_service.dart';
import '../services/home_widget_service.dart';
import '../services/theme_service.dart';
import '../widgets/ticker_avatar.dart';
import '../design/neon_colors.dart';
import '../design/ambient_background.dart';
import '../design/glass_card.dart';
import '../design/rolling_number.dart';
import '../design/tilt_shine_card.dart';
import 'ticker_detail_screen.dart';
import 'wrapped_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PeriodFilter _period = PeriodFilter.all;
  PeriodFilter _incomeChartPeriod = PeriodFilter.year1;
  int? _touchedHeroIndex;

  @override
  void initState() {
    super.initState();
    HomeWidgetService.update();
    StorageService.dataVersion.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    StorageService.dataVersion.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => HomeWidgetService.update();

  String _periodLabel(PeriodFilter f) {
    switch (f) {
      case PeriodFilter.month1:
        return '1 мес';
      case PeriodFilter.month3:
        return '3 мес';
      case PeriodFilter.month6:
        return '6 мес';
      case PeriodFilter.year1:
        return '1 год';
      case PeriodFilter.all:
        return 'Всё время';
    }
  }

  final _sectorColors = const [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFE84393),
    Color(0xFFFDCB6E),
    Color(0xFF00CEC9),
    Color(0xFFD63031),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StorageService.dataVersion,
      builder: (context, _, __) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final timeline = AnalyticsService.portfolioValueTimeline();
    final currentValue = AnalyticsService.currentPortfolioValueRub();
    final unrealizedPnl = AnalyticsService.totalUnrealizedPnlRub();
    final realizedPnl = AnalyticsService.totalRealizedPnlRub();
    final holdings = AnalyticsService.currentHoldings();
    final invested = AnalyticsService.totalInvested(f: _period);
    final income = AnalyticsService.totalIncome(f: _period);
    final totalIncomeAllTime = AnalyticsService.totalIncome(f: PeriodFilter.all);
    final totalProfit = unrealizedPnl + realizedPnl + totalIncomeAllTime;
    final dividendForecastRub = AnalyticsService.totalDividendForecastRub();
    final bySector = AnalyticsService.currentValueBySector();
    final byTicker = AnalyticsService.currentValueByTicker();
    final incomeByMonth = AnalyticsService.incomeByMonth(f: _incomeChartPeriod);
    final concentration = AnalyticsService.topHoldingConcentrationPct();
    final topTicker = AnalyticsService.topHoldingTicker();
    final xirr = AnalyticsService.xirrPercent();
    final taxDue = TaxService.enabled ? TaxService.totalTaxDue() : 0.0;
    final primary = Theme.of(context).colorScheme.primary;

    // Чистая переоценка портфеля за выбранный период: состав (тикер + кол-во)
    // фиксируется на начало периода, покупки/продажи внутри периода на это
    // число не влияют — см. AnalyticsService.portfolioChangeForPeriod.
    // Для "Всё время" метод возвращает null (нет состава "на начало"), и
    // строка изменения за период просто не показывается.
    final periodChange = AnalyticsService.portfolioChangeForPeriod(_period);
    final changeAbs = periodChange?.changeAbs;
    final changePct = periodChange?.changePct;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Цвет hero-карточки берём напрямую из палитры, выбранной в настройках,
    // а не из знака прибыли — так карточка визуально совпадает с тем, что
    // пользователь выбрал в настройках темы.
    final accentColor = ThemeService.accentColor.value;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // --- Hero-карточка стоимости портфеля ---
        TiltShineCard(
          child: GlassCard(
            glowColor: accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Стоимость портфеля',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 6),
                RollingNumber(
                  value: currentValue,
                  formatter: (v) => '${v.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (changeAbs != null && changePct != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          changeAbs >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: isDark ? Colors.white : Colors.grey.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changeAbs >= 0 ? "+" : ""}${changeAbs.toStringAsFixed(0)} (${changePct.toStringAsFixed(1)}%)',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(' за ${_periodLabel(_period).toLowerCase()}',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                if (holdings.isNotEmpty || totalIncomeAllTime != 0 || realizedPnl != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          totalProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: totalProfit >= 0 ? NeonColors.emerald : NeonColors.rose,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: RollingNumber(
                            value: totalProfit,
                            formatter: (v) => 'Общая прибыль: ${v >= 0 ? "+" : ""}${v.toStringAsFixed(0)} ₽',
                            style: TextStyle(
                              color: totalProfit >= 0 ? NeonColors.emerald : NeonColors.rose,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (holdings.isNotEmpty || totalIncomeAllTime != 0 || realizedPnl != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'нереализ. ${unrealizedPnl >= 0 ? "+" : ""}${unrealizedPnl.toStringAsFixed(0)} '
                      '· реализ. ${realizedPnl >= 0 ? "+" : ""}${realizedPnl.toStringAsFixed(0)} '
                      '· доход +${totalIncomeAllTime.toStringAsFixed(0)}',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500, fontSize: 10.5),
                    ),
                  ),
                const SizedBox(height: 16),
                if (timeline.length > 1)
                  SizedBox(
                    height: 130,
                    child: GestureDetector(
                      // Лёгкий тактильный отклик при переходе к новой точке графика —
                      // имитация "ощутимого" прохождения значений при касании.
                      onPanUpdate: (_) {},
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots.map((s) {
                                return LineTooltipItem(
                                  timeline[s.x.toInt()].value.toStringAsFixed(0),
                                  TextStyle(
                                    color: isDark ? NeonColors.emerald : primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                            ),
                            touchCallback: (event, response) {
                              final idx = response?.lineBarSpots?.first.x.toInt();
                              if (idx != null && idx != _touchedHeroIndex && event is! FlPanEndEvent) {
                                _touchedHeroIndex = idx;
                                HapticFeedback.selectionClick();
                              }
                            },
                            getTouchedSpotIndicator: (bar, indicators) => indicators.map((i) {
                              return TouchedSpotIndicatorData(
                                FlLine(color: (isDark ? NeonColors.emerald : primary).withOpacity(0.6), strokeWidth: 1.5),
                                FlDotData(
                                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                    radius: 4.5,
                                    color: isDark ? NeonColors.emerald : primary,
                                    strokeColor: Colors.white,
                                    strokeWidth: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          lineBarsData: [
                            // Широкая полупрозрачная линия под основной — имитация неонового
                            // свечения, которого fl_chart не даёт напрямую через тень.
                            LineChartBarData(
                              spots: [for (int i = 0; i < timeline.length; i++) FlSpot(i.toDouble(), timeline[i].value)],
                              isCurved: true,
                              color: (isDark ? NeonColors.emerald : Colors.white).withOpacity(0.35),
                              barWidth: 7,
                              dotData: const FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots: [for (int i = 0; i < timeline.length; i++) FlSpot(i.toDouble(), timeline[i].value)],
                              isCurved: true,
                              color: isDark ? NeonColors.emerald : Colors.white,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (isDark ? NeonColors.emerald : Colors.white).withOpacity(0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Добавь первую покупку, чтобы увидеть график',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // --- фильтр периода ---
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PeriodFilter.values
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_periodLabel(f)),
                          selected: _period == f,
                          onSelected: (_) => setState(() => _period = f),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _miniStat(context, 'Вложено', invested, Icons.account_balance_wallet_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat(context, 'Доход', income, Icons.payments_outlined)),
            ],
          ),
          if (xirr != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.percent, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Доходность (XIRR)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(
                          '${xirr >= 0 ? "+" : ""}${xirr.toStringAsFixed(1)}% годовых',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: xirr >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (taxDue > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 20, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Налог с продаж (НДФЛ)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(
                          '~${taxDue.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (concentration > 40 && topTicker != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$topTicker занимает ${concentration.toStringAsFixed(0)}% портфеля — низкая диверсификация',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // --- Избранное ---
          ValueListenableBuilder<int>(
            valueListenable: FavoritesService.version,
            builder: (context, _, __) {
              final favs = FavoritesService.all;
              if (favs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Избранное', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: favs.length,
                      itemBuilder: (context, i) {
                        final t = favs[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TickerDetailScreen(ticker: t)),
                            ),
                            child: Column(
                              children: [
                                TickerAvatar(ticker: t, size: 48),
                                const SizedBox(height: 6),
                                Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // --- Состав портфеля ---
          if (holdings.isNotEmpty) ...[
            const Text('Состав портфеля', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...holdings.entries.map((e) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: ListTile(
                    leading: Hero(tag: 'logo-${e.key}', child: TickerAvatar(ticker: e.key, size: 36)),
                    title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${e.value.qty.toStringAsFixed(e.value.qty == e.value.qty.roundToDouble() ? 0 : 2)} шт • ср. ${e.value.avgCost.toStringAsFixed(2)} → ${e.value.displayPrice.toStringAsFixed(2)}${e.value.hasManualPrice ? " ✎" : ""}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Hero(
                              tag: 'value-${e.key}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  e.value.valueRub.toStringAsFixed(0),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ),
                            Text(
                              '${e.value.pnlRub >= 0 ? "+" : ""}${e.value.pnlPct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: e.value.pnlRub >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: FavoritesService.version,
                          builder: (context, _, __) {
                            final isFav = FavoritesService.isFavorite(e.key);
                            return IconButton(
                              icon: Icon(isFav ? Icons.star : Icons.star_border,
                                  size: 20, color: isFav ? Colors.amber : Colors.grey),
                              onPressed: () => FavoritesService.toggle(e.key),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TickerDetailScreen(ticker: e.key)),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // --- Пирог по секторам (только текущие бумаги) ---
          if (bySector.isNotEmpty) ...[
            const Text('Распределение по секторам', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _InteractivePieChart(data: bySector, colors: _sectorColors),
            const SizedBox(height: 24),
          ],

          // --- Пирог по отдельным бумагам (только текущие) ---
          if (byTicker.isNotEmpty) ...[
            const Text('Распределение по бумагам', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _InteractivePieChart(data: byTicker, colors: _sectorColors),
            const SizedBox(height: 24),
          ],

          // --- Прогноз дохода на 12 мес (по факту прошлых выплат) ---
          if (dividendForecastRub > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.query_stats, color: Colors.green, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ожидаемый доход за 12 мес', style: TextStyle(fontSize: 12, color: Colors.green)),
                        const SizedBox(height: 2),
                        Text(
                          '~${dividendForecastRub.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'по факту выплат за прошлый год на сегодняшнее количество бумаг — не гарантия',
                          style: TextStyle(fontSize: 10.5, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- Доход по месяцам ---
          if (StorageService.incomes.isNotEmpty) ...[
            const Text('Дивиденды и купоны по месяцам', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('6 мес'),
                  selected: _incomeChartPeriod == PeriodFilter.month6,
                  onSelected: (_) => setState(() => _incomeChartPeriod = PeriodFilter.month6),
                ),
                ChoiceChip(
                  label: const Text('1 год'),
                  selected: _incomeChartPeriod == PeriodFilter.year1,
                  onSelected: (_) => setState(() => _incomeChartPeriod = PeriodFilter.year1),
                ),
                ChoiceChip(
                  label: const Text('Всё время'),
                  selected: _incomeChartPeriod == PeriodFilter.all,
                  onSelected: (_) => setState(() => _incomeChartPeriod = PeriodFilter.all),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (incomeByMonth.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Нет выплат за выбранный период', style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              _buildIncomeLineChart(context, incomeByMonth),
          ],

          if (holdings.isEmpty && income == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.insights_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Добавь первую покупку,\nчтобы увидеть статистику',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой портфель'),
        actions: [
          IconButton(
            tooltip: 'Итоги периода',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WrappedScreen())),
          ),
        ],
      ),
      body: isDark ? AmbientBackground(profit: totalProfit, child: content) : content,
    );
  }

  static const _monthNames = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  String _monthLabel(String key) {
    final parts = key.split('-');
    final year = parts[0].substring(2);
    final month = int.parse(parts[1]);
    return '${_monthNames[month - 1]} $year';
  }

  Widget _buildIncomeLineChart(BuildContext context, Map<String, double> data) {
    final keys = data.keys.toList();
    final values = data.values.toList();
    final primary = Theme.of(context).colorScheme.primary;
    const pointWidth = 64.0;
    final needsScroll = keys.length > 6;
    final chartWidth = needsScroll ? keys.length * pointWidth : null;

    Widget chart = SizedBox(
      height: 200,
      width: chartWidth,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= keys.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_monthLabel(keys[idx]), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${_monthLabel(keys[s.x.toInt()])}\n${values[s.x.toInt()].toStringAsFixed(0)} ₽',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              curveSmoothness: 0.3,
              color: primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(show: true, color: primary.withOpacity(0.15)),
            ),
          ],
        ),
      ),
    );

    if (needsScroll) {
      chart = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // сразу открывается на последних (самых свежих) месяцах
        child: chart,
      );
    }
    return chart;
  }

  Widget _miniStat(BuildContext context, String label, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(value.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Круговая диаграмма с легендой, по которой можно тапать: касание сектора
/// на пироге или чипа в легенде выделяет соответствующую долю — сектор
/// немного увеличивается и получает контрастную рамку. Повторное касание
/// того же чипа легенды снимает выделение. Центр пирога остаётся пустым.
class _InteractivePieChart extends StatefulWidget {
  final Map<String, double> data;
  final List<Color> colors;

  const _InteractivePieChart({required this.data, required this.colors});

  @override
  State<_InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<_InteractivePieChart> {
  int _touchedIndex = -1;

  // Тап по легенде переключает выбор туда-обратно (тап по тому же чипу
  // снимает выделение).
  void _selectFromLegend(int index) {
    setState(() => _touchedIndex = _touchedIndex == index ? -1 : index);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final colors = widget.colors;
    final total = widget.data.values.fold(0.0, (s, v) => s + v);

    return Column(
      children: [
        SizedBox(
          // Запас по высоте, чтобы увеличенный (выбранный) сектор и его
          // рамка всегда помещались целиком и не обрезались по краю.
          height: 220,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // "Тень" вокруг выбранного сектора — сам fl_chart не умеет
              // рисовать тень отдельно под одним сегментом, поэтому имитируем
              // её мягким цветным свечением вокруг всего графика, в цвет
              // выбранного сектора — это читается как подсветка именно его.
              boxShadow: _touchedIndex != -1
                  ? [
                      BoxShadow(
                        color: colors[_touchedIndex % colors.length].withOpacity(0.5),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                // Реагируем на любое "заинтересованное" касание графика —
                // так тап по самому сектору работает так же надёжно, как
                // тап по чипу легенды под графиком.
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    if (_touchedIndex != -1) {
                      setState(() => _touchedIndex = -1);
                    }
                    return;
                  }
                  final idx = response.touchedSection!.touchedSectionIndex;
                  if (idx != _touchedIndex) {
                    setState(() => _touchedIndex = idx);
                    HapticFeedback.selectionClick();
                  }
                },
              ),
              sections: [
                for (int i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    color: colors[i % colors.length],
                    title: '',
                    radius: _touchedIndex == i ? 56 : 48,
                    // Яркая (не чёрная) рамка на выбранном секторе — белая,
                    // читается на любой теме и любом цвете сектора.
                    borderSide: _touchedIndex == i
                        ? const BorderSide(color: Colors.white, width: 3.5)
                        : BorderSide.none,
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
            swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < entries.length; i++)
              GestureDetector(
                onTap: () => _selectFromLegend(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _touchedIndex == i
                        ? colors[i % colors.length].withOpacity(0.18)
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _touchedIndex == i ? colors[i % colors.length] : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entries[i].key} ${total > 0 ? (entries[i].value / total * 100).toStringAsFixed(0) : 0}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _touchedIndex == i ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
