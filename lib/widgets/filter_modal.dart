import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class FilterModal extends StatefulWidget {
  final RangeValues currentPriceRange;
  final double currentMinRating;
  final String currentSortBy;

  const FilterModal({
    super.key,
    required this.currentPriceRange,
    required this.currentMinRating,
    required this.currentSortBy,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late RangeValues _priceRange;
  late double _minRating;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.currentPriceRange;
    _minRating = widget.currentMinRating;
    _sortBy = widget.currentSortBy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Dishes',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildLabel('Price Range (Rs.)'),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 100,
            max: 5000,
            divisions: 49,
            activeColor: AppTheme.primaryGold,
            inactiveColor: AppTheme.primaryGold.withValues(alpha: 0.1),
            labels: RangeLabels(
              'Rs. ${_priceRange.start.round()}',
              'Rs. ${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),

          const SizedBox(height: 32),
          _buildLabel('Minimum Rating'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3, 4, 5].map((star) {
              final isSelected = _minRating == star.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _minRating = star.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGold
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGold
                          : AppTheme.primaryGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppTheme.warmCharcoal
                              : AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: isSelected
                            ? AppTheme.warmCharcoal
                            : AppTheme.primaryGold,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          _buildLabel('Sort By'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children:
                [
                  'Newest',
                  'Price: Low to High',
                  'Price: High to Low',
                  'Top Rated',
                ].map((sort) {
                  final isSelected = _sortBy == sort;
                  return ChoiceChip(
                    label: Text(sort),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _sortBy = sort),
                    selectedColor: AppTheme.primaryGold,
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isSelected
                          ? AppTheme.warmCharcoal
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'priceRange': _priceRange,
                'minRating': _minRating,
                'sortBy': _sortBy,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.warmCharcoal,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                'APPLY FILTERS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}
