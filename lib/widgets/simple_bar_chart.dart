import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class SimpleBarChart extends StatelessWidget {
  final Map<DateTime, double> data;
  final Color barColor;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.barColor = AppTheme.primaryGold,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedDates = data.keys.toList()..sort();
    final maxValue = data.values.fold(0.0, (max, v) => v > max ? v : max);
    final displayMax = maxValue == 0 ? 1000.0 : maxValue * 1.2;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedDates.map((date) {
          final value = data[date] ?? 0.0;
          final barHeight = (value / displayMax) * 150;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (value > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    value > 999
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toStringAsFixed(0),
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              Container(
                width: 25,
                height: barHeight.clamp(4.0, 150.0),
                decoration: BoxDecoration(
                  color: value > 0 ? barColor : barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  gradient: value > 0
                      ? LinearGradient(
                          colors: [barColor, barColor.withValues(alpha: 0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('E').format(date).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
