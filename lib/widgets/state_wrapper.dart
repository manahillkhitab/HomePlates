import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';

/// Universal state wrapper for AsyncValue handling
/// Provides consistent loading, error, and empty states across the app
class StateWrapper<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget Function()? empty;
  final bool Function(T data)? isEmpty;

  const StateWrapper({
    super.key,
    required this.state,
    required this.data,
    this.loading,
    this.error,
    this.empty,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (value) {
        // Check if data is empty
        final shouldShowEmpty = isEmpty?.call(value) ?? _isDataEmpty(value);
        if (shouldShowEmpty && empty != null) {
          return empty!();
        }
        return data(value);
      },
      loading: () => loading?.call() ?? const _DefaultLoadingState(),
      error: (err, stack) =>
          error?.call(err, stack) ??
          _DefaultErrorState(error: err, stackTrace: stack),
    );
  }

  bool _isDataEmpty(T value) {
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is String) return value.isEmpty;
    return value == null;
  }
}

class _DefaultLoadingState extends StatelessWidget {
  const _DefaultLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryGold,
        strokeWidth: 3,
      ),
    );
  }
}

class _DefaultErrorState extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const _DefaultErrorState({required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.headingMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _getErrorMessage(error),
              style: AppTextStyles.bodyMedium(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    final message = error.toString();
    // Clean up common error prefixes
    return message
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .replaceAll('_Exception: ', '');
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.primaryGold),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.headingMedium(),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.warmCharcoal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
