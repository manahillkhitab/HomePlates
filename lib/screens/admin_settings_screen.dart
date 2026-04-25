import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/config_provider.dart';
import '../utils/app_theme.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _serviceFeeController = TextEditingController();

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _serviceFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncConfig = ref.watch(configProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Command Center',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: asyncConfig.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (config) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Revenue Split', Icons.pie_chart_rounded),
                const SizedBox(height: 20),
                _buildCommissionSlider(
                  label: 'Chef Commission',
                  value: config.chefCommission,
                  onChanged: (val) => ref
                      .read(configProvider.notifier)
                      .updateChefCommission(val),
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: 24),
                _buildCommissionSlider(
                  label: 'Rider Commission',
                  value: config.riderCommission,
                  onChanged: (val) => ref
                      .read(configProvider.notifier)
                      .updateRiderCommission(val),
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 40),
                _buildSectionHeader(
                  'Logistics & Pricing',
                  Icons.delivery_dining_rounded,
                ),
                const SizedBox(height: 24),
                _buildFeeInput(
                  label: 'Base Delivery Fee',
                  value: config.baseDeliveryFee,
                  onChanged: (val) => ref
                      .read(configProvider.notifier)
                      .updateBaseDeliveryFee(val),
                  prefix: 'Rs.',
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Platform Revenue is automatically calculated as: 100% - Chef% - Rider%.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : AppTheme.warmCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildCommissionSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              '${((value > 1 ? value / 100 : value) * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 18,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color.withValues(alpha: 0.3),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: (value > 1 ? value / 100 : value).clamp(0.0, 0.5),
            min: 0.0,
            max: 0.5, // Max 50% for each
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeInput({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required String prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Text(
                prefix,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                  onSubmitted: (val) {
                    final d = double.tryParse(val);
                    if (d != null) onChanged(d);
                  },
                  controller: TextEditingController(
                    text: value.toStringAsFixed(0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
