import 'dart:io';
import 'package:flutter/material.dart';
import '../data/local/models/dish_model.dart';
import '../controllers/order_controller.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import 'my_orders_screen.dart';

class DishDetailScreen extends StatefulWidget {
  final DishModel dish;

  const DishDetailScreen({super.key, required this.dish});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  final OrderController _orderController = OrderController();
  final AuthController _authController = AuthController();
  
  int _quantity = 1;
  bool _isLoading = false;

  double get _totalPrice => widget.dish.price * _quantity;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_authController.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _orderController.createOrder(
      customerId: _authController.currentUser!.id,
      dish: widget.dish,
      quantity: _quantity,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        
        // Navigate to My Orders screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Dish Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dish Image - optimized for visibility
            Container(
              height: 250, // Balanced height to show full image
              color: Colors.grey[200],
              child: widget.dish.imagePath.isNotEmpty
                  ? Image.file(
                      File(widget.dish.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    )
                  : const Icon(Icons.image, size: 100),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0), // Reduced from 24 to 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dish Name
                  Text(
                    widget.dish.name,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 24, // Reduced from 28 to 24
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6), // Reduced from 8
                  
                  // Price
                  Text(
                    'Rs. ${widget.dish.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22, // Reduced from 24 to 22
                      color: AppTheme.mutedSaffron,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16), // Reduced from 24
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6), // Reduced from 8
                  Text(
                    widget.dish.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20), // Reduced from 32
                  
                  // Quantity Selector
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10), // Reduced from 12
                  Row(
                    children: [
                      IconButton(
                        onPressed: _decrementQuantity,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: AppTheme.mutedSaffron,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.mutedSaffron),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _incrementQuantity,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: AppTheme.mutedSaffron,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Reduced from 32
                  
                  // Total Price
                  Container(
                    padding: const EdgeInsets.all(14), // Reduced from 16
                    decoration: BoxDecoration(
                      color: AppTheme.mutedSaffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18, // Reduced from 20
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs. ${_totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 22, // Reduced from 24
                            fontWeight: FontWeight.bold,
                            color: AppTheme.mutedSaffron,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced from 24
                  
                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
