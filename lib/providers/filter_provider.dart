import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState {
  final RangeValues priceRange;
  final double minRating;
  final String sortBy;

  FilterState({
    this.priceRange = const RangeValues(100, 5000),
    this.minRating = 0.0,
    this.sortBy = 'Newest',
  });

  FilterState copyWith({
    RangeValues? priceRange,
    double? minRating,
    String? sortBy,
  }) {
    return FilterState(
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(FilterState());

  void updateFilters({
    RangeValues? priceRange,
    double? minRating,
    String? sortBy,
  }) {
    state = state.copyWith(
      priceRange: priceRange,
      minRating: minRating,
      sortBy: sortBy,
    );
  }

  void reset() {
    state = FilterState();
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>(
  (ref) => FilterNotifier(),
);
