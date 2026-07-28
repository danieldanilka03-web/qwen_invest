import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analytics_service.dart';
import '../design/neon_colors.dart';
import '../design/rolling_number.dart';
import '../widgets/ticker_avatar.dart';

/// Итоги портфеля в формате коротких "сторис" (как Spotify Wrapped) —
/// пролистываются свайпом или тапом, автоматически переключаются по
/// таймеру, в конце — кнопка "поделиться" текстовой сводкой.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _StorySlide {
  final String eyebrow;
  final Widget content;
  final Color accent;
  const _StorySlide({required this.eyebrow, required this.content, required this.accent});
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _pageController = PageController();
  Timer? _timer;
  int _index = 0;
  late final List<_StorySlide> _slides;
  late final String _shareText;

  static const _slideDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _buildSlides();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_slideDuration, _next);
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  void _prev() {
    if (_index > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  void _buildSlides() {
    final value = AnalyticsService.currentPortfolioValueRub();
    final unrealized = AnalyticsService.totalUnrealizedPnlRub();
    final realized = AnalyticsService.totalRealizedPnlRub();
    final income = AnalyticsService.totalIncome(f: PeriodFilter.all);
    final totalProfit = unrealized + realized + income;
    final topTicker = AnalyticsService.topHoldingTicker();
    final concentration = AnalyticsService.topHoldingConcentrationPct();
    final forecast = AnalyticsService.totalDividendForecastRub();
    final xirr = AnalyticsService.xirrPercent();

    String riskLabel;
    Color riskColor;
    if (concentration >= 50) {
      riskLabel = 'Высокая концентрация';
      riskColor = NeonColors.rose;
    } else if (concentration >= 25) {
      riskLabel = 'Умеренная концентрация';
      riskColor = Colors.amber;
    } else {
      riskLabel = 'Хорошая диверсификация';
      riskColor = NeonColors.emerald;
    }

    _slides = [
      _StorySlide(
        eyebrow: 'ИТОГИ ПОРТФЕЛЯ',
        accent: NeonColors.emerald,
        content: _bigNumberSlide(
          title: 'Сейчас портфель стоит',
          value: value,
          suffix: ' ₽',
          color: NeonColors.emerald,
        ),
      ),
      _StorySlide(
        eyebrow: 'ГЛАВНЫЙ АКТИВ',
        accent: NeonColors.cyan,
        content: topTicker == null
            ? _textSlide('Пока в портфеле нет бумаг — самое время начать')
            : _topAssetSlide(topTicker, concentration),
      ),
      _StorySlide(
        eyebrow: 'ПРИБЫЛЬ',
        accent: totalProfit >= 0 ? NeonColors.emerald : NeonColors.rose,
        content: _bigNumberSlide(
          title: totalProfit >= 0 ? 'Суммарно ты заработал' : 'Суммарный результат',
          value: totalProfit,
          suffix: ' ₽',
          color: totalProfit >= 0 ? NeonColors.emerald : NeonColors.rose,
          showSign: true,
        ),
      ),
      _StorySlide(
        eyebrow: 'УРОВЕНЬ РИСКА',
        accent: riskColor,
        content: _riskSlide(riskLabel, riskColor, concentration, xirr),
      ),
      _StorySlide(
        eyebrow: 'ДОХОД',
        accent: NeonColors.violet,
        content: _bigNumberSlide(
          title: 'Дивидендами и купонами получено',
          value: income,
          suffix: ' ₽',
          color: NeonColors.violet,
          subtitle: forecast > 0 ? 'Прогноз на следующие 12 мес: ~${forecast.toStringAsFixed(0)} ₽' : null,
        ),
      ),
      _StorySlide(
        eyebrow: 'ГОТОВО',
        accent: NeonColors.emerald,
        content: _shareSlide(value, totalProfit),
      ),
    ];

    _shareText = 'Мой портфель в Invest Tracker: ${value.toStringAsFixed(0)} ₽, '
        'общая прибыль ${totalProfit >= 0 ? "+" : ""}${totalProfit.toStringAsFixed(0)} ₽'
        '${topTicker != null ? ", главный актив — $topTicker" : ""}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.bgDeep,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                final w = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < w / 3) {
                  _prev();
                } else {
                  _next();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _startTimer();
                },
                itemBuilder: (context, i) => _slideScaffold(_slides[i]),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(_slides.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _index ? Colors.white : Colors.white.withOpacity(0.25),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 18,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slideScaffold(_StorySlide slide) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [slide.accent.withOpacity(0.16), NeonColors.bgDeep],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            slide.eyebrow,
            style: TextStyle(color: slide.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 28),
          slide.content,
        ],
      ),
    );
  }

  Widget _bigNumberSlide({
    required String title,
    required double value,
    required String suffix,
    required Color color,
    bool showSign = false,
    String? subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        RollingNumber(
          value: value,
          duration: const Duration(milliseconds: 1200),
          formatter: (v) => '${showSign && v >= 0 ? "+" : ""}${v.toStringAsFixed(0)}$suffix',
          style: TextStyle(color: color, fontSize: 42, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 16),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _topAssetSlide(String ticker, double concentration) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Больше всего в портфеле занимает', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 20),
        TickerAvatar(ticker: ticker, size: 88),
        const SizedBox(height: 16),
        Text(ticker, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('${concentration.toStringAsFixed(0)}% портфеля', style: TextStyle(color: NeonColors.cyan, fontSize: 15)),
      ],
    );
  }

  Widget _riskSlide(String label, Color color, double concentration, double? xirr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          concentration >= 50 ? Icons.warning_amber_rounded : Icons.shield_outlined,
          color: color,
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(label, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Топ-бумага занимает ${concentration.toStringAsFixed(0)}% портфеля',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        if (xirr != null) ...[
          const SizedBox(height: 20),
          Text('Доходность (XIRR)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          Text(
            '${xirr >= 0 ? "+" : ""}${xirr.toStringAsFixed(1)}% годовых',
            style: TextStyle(color: xirr >= 0 ? NeonColors.emerald : NeonColors.rose, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget _textSlide(String text) {
    return Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16));
  }

  Widget _shareSlide(double value, double totalProfit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, color: NeonColors.emerald, size: 48),
        const SizedBox(height: 16),
        const Text('Вот и всё на сегодня', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Share.share(_shareText),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Поделиться итогами'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
