import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../data/local/models/order_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';

class AdminOrderListScreen extends ConsumerStatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  ConsumerState<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends ConsumerState<AdminOrderListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _selectedStatus = 'all';
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    
    // 1. Initial Load from Hive (Local Database)
    try {
      final orderBox = Hive.box<OrderModel>(AppConstants.orderBox);
      if (orderBox.isNotEmpty) {
        setState(() {
          _orders = orderBox.values.map((o) => {
            'id': o.id,
            'customer_id': o.customerId,
            'chef_id': o.chefId,
            'dish_id': o.dishId,
            'dish_name': o.dishName,
            'dish_image_path': o.dishImagePath,
            'quantity': o.quantity,
            'total_price': o.totalPrice,
            'status': o.status.name,
            'created_at': o.createdAt.toIso8601String(),
            'rider_id': o.riderId,
            'refund_status': o.refundStatus.name,
            'cancel_reason': o.cancelReason,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading local orders: $e');
    }

    // 2. Refresh from Cloud if Online
    try {
      final res = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _orders = res as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders from cloud: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> orderData, String newStatusStr) async {
    try {
      final newStatus = OrderStatus.values.firstWhere((e) => e.name.toLowerCase() == newStatusStr.toLowerCase());
      final order = OrderModel(
        id: orderData['id'],
        customerId: orderData['customer_id'],
        chefId: orderData['chef_id'],
        dishId: orderData['dish_id'],
        dishName: orderData['dish_name'],
        dishImagePath: orderData['dish_image_path'] ?? '',
        quantity: orderData['quantity'],
        pricePerItem: (orderData['total_price'] as num).toDouble() / orderData['quantity'],
        totalPrice: (orderData['total_price'] as num).toDouble(),
        status: OrderStatus.values.firstWhere((e) => e.name == orderData['status'], orElse: () => OrderStatus.pending),
        createdAt: DateTime.parse(orderData['created_at']),
        riderId: orderData['rider_id'],
      );

      final currentUser = ref.read(authProvider).value;
      if (currentUser != null) {
        await ref.read(orderProvider.notifier).updateOrderStatus(
          order: order, 
          newStatus: newStatus, 
          currentUser: currentUser,
        );
        
        // Also update Supabase for global consistency
        await _supabase.from('orders').update({'status': newStatus.name}).eq('id', order.id);
        
        await _fetchOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to ${newStatus.name}')));
        }
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  Future<void> _updateRefundStatus(String orderId, String refundStatus) async {
    try {
      await _supabase.from('orders').update({'refund_status': refundStatus}).eq('id', orderId);
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refund status updated to $refundStatus')));
      }
    } catch (e) {
      debugPrint('Error updating refund status: $e');
    }
  }

  List<dynamic> get _filteredOrders {
    if (_selectedStatus == 'all') return _orders;
    return _orders.where((order) => 
        (order['status'] as String).toLowerCase() == _selectedStatus.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('System Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Cooking', 'cooking'),
                const SizedBox(width: 8),
                _buildFilterChip('Picked Up', 'pickedUp'),
                const SizedBox(width: 8),
                _buildFilterChip('Delivered', 'delivered'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                : _filteredOrders.isEmpty
                    ? Center(child: Text('No orders found', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final status = order['status'] as String;
                          final price = (order['total_price'] as num).toDouble();
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                              ),
                              title: Text(order['dish_name'] ?? 'Dish', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rs. ${price.toStringAsFixed(0)} • Qty: ${order['quantity']}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: _getStatusColor(status),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showOrderDetail(order),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatus = value);
      },
      selectedColor: AppTheme.primaryGold.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGold : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.grey;
      case 'accepted': return Colors.blue;
      case 'cooking': return Colors.orange;
      case 'ready': return Colors.amber;
      case 'pickedup': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.timer_outlined;
      case 'cooking': return Icons.restaurant;
      case 'delivered': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.receipt_long;
    }
  }

  void _showOrderDetail(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Order Review', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _detailRow('Order ID', order['id'].toString().substring(0, 8).toUpperCase()),
            _detailRow('Dish', order['dish_name']),
            _detailRow('Total Price', 'Rs. ${order['total_price']}'),
            _detailRow('Status', (order['status'] as String).toUpperCase()),
            _detailRow('Customer ID', order['customer_id']),
            _detailRow('Chef ID', order['chef_id']),
            _detailRow('Placed At', DateTime.parse(order['created_at']).toLocal().toString().substring(0, 16)),
            _detailRow('Refund Status', (order['refund_status'] ?? 'none').toString().toUpperCase()),
            if (order['cancel_reason'] != null)
              _detailRow('Cancel Reason', order['cancel_reason']),
            const SizedBox(height: 32),
            if (order['status'] != 'canceled' && order['status'] != 'delivered' && order['status'] != 'rejected')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateOrderStatus(order, 'canceled');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('FORCE CANCEL ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 12),
            if (order['status'] == 'canceled' || order['status'] == 'rejected')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateRefundStatus(order['id'], 'full');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('REFUND FULL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateRefundStatus(order['id'], 'partial');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      child: const Text('REFUND PARTIAL'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.warmCharcoal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
