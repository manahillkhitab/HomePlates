import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/order_model.dart';
import '../data/local/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../utils/constants.dart';
import 'leave_review_screen.dart';
import '../widgets/live_map_widget.dart';
import 'legal_screen.dart';
import 'chat_screen.dart';

import '../data/local/services/sync_service.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  
  @override
  void initState() {
    super.initState();
    // Pre-emptive sync when opening tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SyncService().syncAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await SyncService().syncAll();
        },
        color: AppTheme.primaryGold,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Track Journey',
                style: AppTextStyles.headingLarge(color: AppTheme.primaryGold),
              ),
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.gavel_rounded, color: AppTheme.primaryGold),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalScreen())),
                  tooltip: 'Legal & Safety',
                ),
                IconButton(
                  icon: const Icon(Icons.report_problem_rounded, color: Colors.redAccent),
                  onPressed: () => _showReportDialog(context, widget.order.id),
                  tooltip: 'Report Issue',
                ),
                const SizedBox(width: 8),
              ],
            ),
          ValueListenableBuilder(
            valueListenable: Hive.box<OrderModel>(AppConstants.orderBox).listenable(keys: [widget.order.id]),
            builder: (context, Box<OrderModel> box, _) {
              final liveOrder = box.get(widget.order.id) ?? widget.order;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ORDER #${liveOrder.id.substring(liveOrder.id.length - 6).toUpperCase()}',
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3), 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Rs. ${liveOrder.totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900, 
                                  color: AppTheme.primaryGold, 
                                  fontSize: 20
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            liveOrder.dishName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900, 
                              fontSize: 24, 
                              letterSpacing: -0.5
                            ),
                          ),
                          if (liveOrder.items != null && liveOrder.items!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            ...liveOrder.items!.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.name}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                  ),
                                  Text(
                                    'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                    if (liveOrder.status == OrderStatus.pickedUp || liveOrder.status == OrderStatus.delivered) ...[
                      const SizedBox(height: 32),
                      LiveMapWidget(orderId: liveOrder.id),
                    ],
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'DELIVERY MILESTONES',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900, 
                            fontSize: 12, 
                            letterSpacing: 2, 
                            color: AppTheme.primaryGold
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildTimeline(context, liveOrder.status),
                    
                    if (liveOrder.status == OrderStatus.pickedUp) ...[
                      const SizedBox(height: 24),
                      _buildContactActions(context, 'Rider'),
                    ] else if (liveOrder.status == OrderStatus.accepted || liveOrder.status == OrderStatus.cooking || liveOrder.status == OrderStatus.ready) ...[
                      const SizedBox(height: 24),
                      _buildContactActions(context, 'Chef'),
                    ],
                    
                    if (liveOrder.status == OrderStatus.delivered) ...[
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                             Navigator.push(
                               context, 
                               MaterialPageRoute(builder: (context) => LeaveReviewScreen(order: liveOrder, customerName: user?.name ?? 'Customer'))
                             );
                          },
                          icon: const Icon(Icons.star_rounded, size: 22),
                          label: Text(
                            'RATE YOUR DELICACY', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: AppTheme.warmCharcoal,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],

                    if (liveOrder.status == OrderStatus.pending) ...[
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCancelOrder(context, ref, liveOrder, user),
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          label: Text(
                            'CANCEL ORDER', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1.2)
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Note: Cancellation only available while pending',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTimeline(BuildContext context, OrderStatus currentStatus) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final steps = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.cooking,
      OrderStatus.ready,
      OrderStatus.pickedUp,
      OrderStatus.delivered,
    ];

    if (currentStatus == OrderStatus.rejected || currentStatus == OrderStatus.canceled) {
       final isCanceled = currentStatus == OrderStatus.canceled;
       return Container(
         padding: const EdgeInsets.all(32),
         decoration: BoxDecoration(
           color: (isCanceled ? Colors.grey : Colors.redAccent).withValues(alpha: 0.05),
           borderRadius: BorderRadius.circular(AppTheme.cardRadius),
           border: Border.all(color: (isCanceled ? Colors.grey : Colors.redAccent).withValues(alpha: 0.1)),
         ),
         child: Column(
           children: [
             Icon(
               isCanceled ? Icons.do_not_disturb_on_rounded : Icons.cancel_rounded, 
               color: isCanceled ? Colors.grey : Colors.redAccent, 
               size: 80
             ),
             const SizedBox(height: 24),
             Text(
               isCanceled ? 'Order Canceled' : 'Mission Aborted',
               style: GoogleFonts.outfit(
                 color: isCanceled ? Colors.grey : Colors.redAccent, 
                 fontWeight: FontWeight.w900, 
                 fontSize: 24
               ),
             ),
             const SizedBox(height: 12),
             Text(
               isCanceled 
                ? 'You have canceled this order. We hope to serve you again soon!'
                : 'The chef is currently unable to fulfill this request. Any payment will be refunded.',
               style: GoogleFonts.outfit(
                 color: theme.colorScheme.onSurface.withValues(alpha: 0.4), 
                 fontWeight: FontWeight.w600,
                 fontSize: 14,
               ),
               textAlign: TextAlign.center,
             ),
           ],
         ),
       );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final stepStatus = steps[index];
        final isActive = currentStatus.index >= stepStatus.index;
        final isCurrent = currentStatus == stepStatus;
        
        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: index == 0,
          isLast: index == steps.length - 1,
          indicatorStyle: IndicatorStyle(
            width: isCurrent ? 36 : 24,
            height: isCurrent ? 36 : 24,
            indicator: Container(
              decoration: BoxDecoration(
                color: isActive ? _getStatusColor(stepStatus) : (isDark ? Colors.white10 : Colors.grey[200]),
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: Colors.white, width: 4) : null,
                boxShadow: isCurrent ? [BoxShadow(color: _getStatusColor(stepStatus).withValues(alpha: 0.4), blurRadius: 12)] : null,
              ),
              child: isCurrent 
                  ? Icon(_getStatusIcon(stepStatus), color: Colors.white, size: 18)
                  : null,
            ),
            padding: const EdgeInsets.all(6),
          ),
          beforeLineStyle: LineStyle(
            color: isActive ? _getStatusColor(stepStatus) : (isDark ? Colors.white10 : Colors.grey[200]!),
            thickness: 4,
          ),
          afterLineStyle: LineStyle(
            color: (index < steps.length - 1 && currentStatus.index > stepStatus.index) 
                ? _getStatusColor(steps[index + 1]) 
                : (isDark ? Colors.white10 : Colors.grey[200]!),
            thickness: 4,
          ),
          endChild: Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 40),
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                 Expanded(
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(stepStatus).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 6),
                        Text(
                          'LIVE UPDATING...',
                          style: GoogleFonts.outfit(
                            fontSize: 11, 
                            fontWeight: FontWeight.w800, 
                            color: AppTheme.primaryGold, 
                            letterSpacing: 1.5
                          ),
                        ),
                      ],
                    ],
                   ),
                 ),
                 Icon(
                    _getStatusIcon(stepStatus), 
                    color: isActive ? _getStatusColor(stepStatus).withValues(alpha: 0.6) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    size: 28,
                 ),
               ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.blueGrey;
      case OrderStatus.accepted: return Colors.blueAccent;
      case OrderStatus.cooking: return Colors.orangeAccent;
      case OrderStatus.ready: return Colors.amber;
      case OrderStatus.pickedUp: return Colors.purpleAccent;
      case OrderStatus.delivered: return Colors.greenAccent;
      case OrderStatus.rejected: return Colors.redAccent;
      case OrderStatus.canceled: return Colors.grey;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.receipt_long_rounded;
      case OrderStatus.accepted: return Icons.verified_user_rounded;
      case OrderStatus.cooking: return Icons.restaurant_rounded;
      case OrderStatus.ready: return Icons.inventory_2_rounded;
      case OrderStatus.pickedUp: return Icons.moped_rounded;
      case OrderStatus.delivered: return Icons.home_work_rounded;
      case OrderStatus.rejected: return Icons.cancel_rounded;
      case OrderStatus.canceled: return Icons.do_not_disturb_on_rounded;
    }
  }

  String _getStatusTitle(OrderStatus status) {
     switch (status) {
      case OrderStatus.pending: return 'Order Placed';
      case OrderStatus.accepted: return 'Chef Confirmed';
      case OrderStatus.cooking: return 'Now Sizzling';
      case OrderStatus.ready: return 'Ready for Pickup';
      case OrderStatus.pickedUp: return 'In Transit';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.rejected: return 'Rejected';
      case OrderStatus.canceled: return 'Canceled';
    }
  }

  void _handleCancelOrder(BuildContext context, WidgetRef ref, OrderModel order, UserModel? user) async {
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to cancel this order? This action cannot be undone.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NO, KEEP IT', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('YES, CANCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(orderProvider.notifier).updateOrderStatus(
        order: order,
        newStatus: OrderStatus.canceled,
        currentUser: user,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order canceled successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to cancel order. It might already be in progress.')),
          );
        }
      }
    }
  }

  Widget _buildContactActions(BuildContext context, String role) {
    return Row(
      children: [
        Expanded(
          child: _buildSupportButton(
            context,
            Icons.phone_in_talk_rounded,
            'Call $role',
            Colors.green,
            () => _showFakeCall(context, role),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSupportButton(
            context,
            Icons.chat_bubble_rounded,
            'Message',
            AppTheme.primaryGold,
            () => _openChat(context, role),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFakeCall(BuildContext context, String role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dialing ${role}\'s number... 📞')),
    );
  }

  void _openChat(BuildContext context, String role) {
    // Determine the other user ID based on role
    // If tracking order, we are likely the Customer
    // If role is Rider, we chat with riderId. If Chef, chefId.
    
    // NOTE: In a real app we'd need more robust logic to know EXACTLY who we are chatting with
    // For now, we use the order's IDs.
    
    String? targetId;
    String targetName = '$role';
    
    if (role == 'Chef') {
      targetId = widget.order.chefId;
      targetName = widget.order.dishName.isNotEmpty ? 'Chef (Kitchen)' : 'Chef'; 
    } else if (role == 'Rider') {
      targetId = widget.order.riderId;
      targetName = 'Rider';
    }

    if (targetId != null) {
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            otherUserId: targetId!,
            otherUserName: targetName,
          ),
        ),
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot chat: User not assigned yet.')),
      );
    }
  }

  void _showReportDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Issue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please describe the problem with your order:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Food quality, delivery delay...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted to Admin. We will review it shortly.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('SUBMIT REPORT'),
          ),
        ],
      ),
    );
  }
}
