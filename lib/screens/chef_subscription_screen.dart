import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/local/models/user_model.dart';
import '../data/local/models/subscription_model.dart';
import '../utils/app_theme.dart';

class ChefSubscriptionScreen extends ConsumerWidget {
  const ChefSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'PREMIUM TIERS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCurrentStatusCard(user, isDark),
            const SizedBox(height: 32),
            Text(
              'CHOOSE YOUR PLAN',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            ...SubscriptionModel.availableTiers.map(
              (tier) => _buildTierCard(context, ref, user, tier, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(UserModel user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PLAN',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
              color: AppTheme.warmCharcoal.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.subscriptionTier.name.toUpperCase(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: AppTheme.warmCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep more of your earnings with premium tiers.',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.warmCharcoal.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    SubscriptionModel tier,
    bool isDark,
  ) {
    final bool isCurrent = user.subscriptionTier == tier.tier;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryGold : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.tier.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      tier.monthlyPrice == 0
                          ? 'Always Free'
                          : 'Rs. ${tier.monthlyPrice}/mo',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  ],
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            ...tier.perks.map(
              (perk) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      perk,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent
                    ? null
                    : () => _handleUpgrade(context, ref, user, tier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? Colors.grey
                      : AppTheme.primaryGold,
                  foregroundColor: AppTheme.warmCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isCurrent
                      ? 'CURRENT PLAN'
                      : 'UPGRADE TO ${tier.tier.name.toUpperCase()}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    SubscriptionModel tier,
  ) async {
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Plan?'),
        content: Text(
          'Would you like to upgrade to the ${tier.tier.name} tier for Rs. ${tier.monthlyPrice}/mo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('UPGRADE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            user.copyWith(
              subscriptionTier: tier.tier,
              subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully upgraded to ${tier.tier.name.toUpperCase()}! 🚀',
            ),
          ),
        );
      }
    }
  }
}
