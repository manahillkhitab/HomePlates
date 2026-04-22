import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../data/local/models/user_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_spacing.dart';
import '../widgets/app_button.dart';
import 'customer_home_screen.dart';
import 'chef_home_screen.dart';
import 'rider_home_screen.dart';
import 'admin_dashboard_screen.dart';
import 'verification_screen.dart';


class SignupScreen extends ConsumerStatefulWidget {
  final UserRole selectedRole;

  const SignupScreen({super.key, required this.selectedRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  final _confirmPasswordController = TextEditingController();
  final _kitchenNameController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  
  String _selectedVehicleType = 'Bike';
  bool _termsAccepted = false;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _kitchenNameController.dispose();
    _categoriesController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool completed = await ref.read(authProvider.notifier).signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        role: widget.selectedRole,
        kitchenName: _kitchenNameController.text.trim(),
        categories: _categoriesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        vehicleType: widget.selectedRole == UserRole.rider ? _selectedVehicleType : '',
        vehicleNumber: _vehicleNumberController.text.trim(),
        termsAccepted: _termsAccepted,
      );

      if (mounted) {
        if (!completed) {
          // Navigate to Verification Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text.trim(),
                userRole: widget.selectedRole,
              ),
            ),
          );
        } else {
          // Email confirmed immediately (Dev bypass)
          Widget home;
          switch (widget.selectedRole) {
            case UserRole.customer: home = const CustomerHomeScreen(); break;
            case UserRole.chef: home = const ChefHomeScreen(); break;
            case UserRole.rider: home = const RiderHomeScreen(); break;
            case UserRole.admin: home = AdminDashboardScreen();break;
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => home),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 90, // Reduced from 120
            floating: true, pinned: true, elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced vertical padding
              title: Text(
                'Let\'s get started!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20, // Slightly reduced font size
                  color: AppTheme.mutedSaffron,
                ),
              ),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12), // Reduced vertical padding
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  height: 64, // Reduced from 80
                  width: 64,  // Reduced from 80
                  decoration: BoxDecoration(
                    color: AppTheme.mutedSaffron.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, color: AppTheme.mutedSaffron, size: 32),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Join HomePlates as a ${widget.selectedRole.name.toUpperCase()}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'FULL NAME *',
                      hint: 'John Doe',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      validator: (value) => (value?.isEmpty ?? true) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: 'EMAIL ADDRESS *',
                      hint: 'john@example.com',
                      icon: Icons.email_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value?.contains('@') ?? false) ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _phoneController,
                      label: widget.selectedRole == UserRole.customer ? 'PHONE NUMBER' : 'PHONE NUMBER *',
                      hint: '+92 300 1234567',
                      icon: Icons.phone_android_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (widget.selectedRole != UserRole.customer && (value?.isEmpty ?? true)) {
                          return 'Phone is required for this role';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Role Specific Fields
                    if (widget.selectedRole == UserRole.chef) ...[
                      _buildTextField(
                        controller: _kitchenNameController,
                        label: 'KITCHEN / BUSINESS NAME',
                        hint: 'Mama\'s Kitchen',
                        icon: Icons.storefront_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _categoriesController,
                        label: 'FOOD CATEGORIES (Comma separated)',
                        hint: 'Desserts, Snacks, Main Course',
                        icon: Icons.category_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (widget.selectedRole == UserRole.rider) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'VEHICLE TYPE',
                              style: AppTextStyles.labelSmall(
                                color: AppTheme.primaryGold,
                              ).copyWith(letterSpacing: 1, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedVehicleType,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGold),
                                items: ['Bike', 'Car', 'Cycle', 'Other'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: AppTextStyles.bodyLarge().copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedVehicleType = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _vehicleNumberController,
                        label: 'VEHICLE NUMBER',
                        hint: 'ABC-1234',
                        icon: Icons.numbers_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildTextField(
                      controller: _addressController,
                      label: 'PRIMARY ADDRESS',
                      hint: 'Street, City, Area',
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: 'PASSWORD *',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.primaryGold.withValues(alpha: 0.5),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'CONFIRM PASSWORD *',
                      hint: '••••••••',
                      icon: Icons.lock_clock_outlined,
                      isDark: isDark,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.primaryGold.withValues(alpha: 0.5),
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                         if (value != _passwordController.text) return 'Passwords do not match';
                         return null;
                      },
                    ),
                    const SizedBox(height: 16), // Reduced from 20

                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: AppTheme.primaryGold,
                          onChanged: (val) => setState(() => _termsAccepted = val!),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduced click area
                        ),
                        Expanded(
                          child: Text(
                            'I accept the Terms & Conditions',
                            style: AppTextStyles.caption(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24), // Reduced from 40
                    
                    AppButton.primary(
                      text: _isLoading ? 'CREATING ACCOUNT...' : 'REGISTER NOW',
                      onPressed: _isLoading ? null : _handleSignup,
                      isExpanded: true,
                      height: 52, // Reduced height
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16), // Reduced from 24
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodyMedium(),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Login',
                            style: AppTextStyles.labelLarge(color: AppTheme.primaryGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40), // Reduced from 100
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.labelSmall(
              color: AppTheme.primaryGold,
            ).copyWith(letterSpacing: 1, fontWeight: FontWeight.w900),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: AppTextStyles.bodyLarge().copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
            prefixIcon: Icon(icon, color: AppTheme.primaryGold.withValues(alpha: 0.5)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppTheme.darkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }
}
