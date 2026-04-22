import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/promo_provider.dart';

import '../data/local/models/cart_summary.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/user_model.dart';

import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/speech_service.dart';

import '../widgets/app_button.dart';

import 'my_orders_screen.dart';
import 'wallet_screen.dart';

class CheckoutReviewScreen extends ConsumerStatefulWidget {
  final CartSummary cart;
  const CheckoutReviewScreen({super.key, required this.cart});

  @override
  ConsumerState<CheckoutReviewScreen> createState() => _CheckoutReviewScreenState();
}

class _CheckoutReviewScreenState extends ConsumerState<CheckoutReviewScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cashOnDelivery;
  bool _isPlacingOrder = false;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isListening = false;
  String? _promoError;
  final double _deliveryFee = 50.0;

  double get _discount {
    final promo = ref.watch(appliedPromoProvider);
    if (promo == null) return 0.0;
    return (widget.cart.total * promo.discountPercentage).clamp(0, promo.maxDiscount);
  }

  double get _grandTotal => widget.cart.total + _deliveryFee - _discount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        _addressController.text = user.address;
      }
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).value;
    final walletBalance = user != null ? (ref.watch(walletProvider(user.id)).balance) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.warmCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review Order',
          style: AppTextStyles.displayMedium(color: AppTheme.primaryGold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Delivery Address'),
            const SizedBox(height: AppSpacing.sm),
            _buildAddressCard(_addressController.text, isDark),
            
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Payment Method'),
            const SizedBox(height: AppSpacing.sm),
            _buildPaymentMethod(
              PaymentMethod.cashOnDelivery,
              'Cash on Delivery',
              'Pay when you receive your meal',
              Icons.payments_rounded,
              isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildPaymentMethod(
              PaymentMethod.wallet,
              'Wallet Balance',
              'Current Balance: Rs. ${walletBalance.toStringAsFixed(0)}',
              Icons.account_balance_wallet_rounded,
              isDark,
              isEnabled: walletBalance >= _grandTotal,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Special Instructions'),
            const SizedBox(height: AppSpacing.sm),
            _buildSpecialInstructions(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Order Summary'),
            const SizedBox(height: AppSpacing.sm),
            _buildOrderSummary(isDark),
            
            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Promo Code'),
            const SizedBox(height: AppSpacing.sm),
            _buildPromoCodeInput(isDark),
            
            const SizedBox(height: 40),
            AppButton.primary(
              text: 'CONFIRM & PAY',
              onPressed: _handlePlaceOrder,
              isLoading: _isPlacingOrder,
              isExpanded: true,
              height: 56,
              textStyle: AppTextStyles.headingSmall(color: AppTheme.warmCharcoal).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.labelMedium(color: AppTheme.primaryGold).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }

  Widget _buildAddressCard(String address, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  address.isEmpty ? 'Tap Edit to set address' : address,
                  style: AppTextStyles.bodyLarge(color: isDark ? Colors.white : AppTheme.warmCharcoal),
                ),
              ),
              TextButton(
                onPressed: _showAddressEditDialog,
                child: Text('EDIT', style: AppTextStyles.labelLarge(color: AppTheme.primaryGold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddressEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Delivery Address', style: AppTextStyles.headingMedium()),
        content: TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter complete delivery address...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
          onChanged: (val) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('DONE', style: AppTextStyles.labelLarge(color: AppTheme.primaryGold)),
          ),
        ],
      ),
    ).then((_) => setState(() {}));
  }

  Widget _buildPaymentMethod(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    bool isDark, {
    bool isEnabled = true,
  }) {
    final isSelected = _selectedMethod == method;
    
    return InkWell(
      onTap: isEnabled ? () => setState(() => _selectedMethod = method) : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGold : Colors.grey),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSmall(color: isDark ? Colors.white : AppTheme.warmCharcoal)),
                  Text(subtitle, style: AppTextStyles.bodySmall(color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) 
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGold)
            else if (!isEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Insufficient', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WalletScreen())),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('RECHARGE', style: AppTextStyles.caption(color: AppTheme.primaryGold).copyWith(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Items Total', 'Rs. ${widget.cart.total.toStringAsFixed(0)}'),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Discount', '- Rs. ${_discount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery Fee', 'Rs. ${_deliveryFee.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildSummaryRow('Grand Total', 'Rs. ${_grandTotal.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _isListening ? AppTheme.primaryGold : AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Any special instructions? (e.g. less spicy)',
          hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: IconButton(
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening ? Colors.redAccent : AppTheme.primaryGold,
            ),
            onPressed: _toggleListening,
          ),
        ),
      ),
    );
  }

  void _toggleListening() async {
    final speech = SpeechService();
    if (_isListening) {
      await speech.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await speech.startListening(
        onResult: (text) {
          setState(() {
            _notesController.text = text;
          });
        },
        onDone: () {
          setState(() => _isListening = false);
        },
      );
    }
  }

  Widget _buildPromoCodeInput(bool isDark) {
    final promo = ref.watch(appliedPromoProvider);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              enabled: promo == null,
              decoration: InputDecoration(
                hintText: promo != null ? 'Code Applied: ${promo.code}' : 'Enter code (e.g. WELCOME10)',
                hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                errorText: _promoError,
              ),
            ),
          ),
          if (promo != null)
            TextButton(
              onPressed: () => ref.read(appliedPromoProvider.notifier).state = null,
              child: Text('REMOVE', style: AppTextStyles.labelLarge(color: Colors.redAccent)),
            )
          else
            AppButton.primary(
              text: 'APPLY',
              onPressed: _validatePromo,
              height: 40,
              isExpanded: false,
              backgroundColor: AppTheme.primaryGold,
              textStyle: AppTextStyles.labelLarge(color: AppTheme.warmCharcoal).copyWith(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final promo = await ref.read(promoProvider.notifier).validatePromo(code, widget.cart.total);

    if (promo != null) {
      setState(() {
        _promoError = null;
        ref.read(appliedPromoProvider.notifier).state = promo;
      });
      _promoController.clear();
    } else {
      setState(() => _promoError = 'Invalid or expired code');
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyLarge(
          color: isDiscount ? Colors.green : (isTotal ? null : Colors.grey),
        ).copyWith(fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
        Text(value, style: AppTextStyles.headingSmall(
          color: isTotal ? AppTheme.primaryGold : (isDiscount ? Colors.green : null),
        )),
      ],
    );
  }

  Future<void> _handlePlaceOrder() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isPlacingOrder = true);

    final success = await ref.read(orderProvider.notifier).createOrderFromCart(
      customer: user,
      cart: widget.cart,
      items: widget.cart.items.map((e) => OrderItem(
          dishId: e.dishId,
          name: e.name,
          price: e.price,
          quantity: e.quantity,
          imagePath: e.imagePath,
          selectedOptions: e.selectedOptions,
        )).toList(),
      paymentMethod: _selectedMethod,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      deliveryAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
    );

    if (mounted) {
      setState(() => _isPlacingOrder = false);
      if (success) {
        await ref.read(cartProvider.notifier).clearCart();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
          (route) => route.isFirst,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully! 🚀')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    }
  }
}

extension on Widget {
  Widget opacity(double opacity) => Opacity(opacity: opacity, child: this);
}
