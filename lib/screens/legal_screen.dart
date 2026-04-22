import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final bool showAgreeButton;
  
  const LegalScreen({super.key, this.showAgreeButton = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Legal & Safety', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Terms & Conditions',
              'By using HomePlates, you agree to connect with local home chefs for food preparation and delivery. HomePlates acts as a platform and is not responsible for the quality of food, though we verify all chefs.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Food Safety Disclaimer',
              'All chefs on HomePlates are required to maintain high hygiene standards. However, since food is prepared in domestic kitchens, users with severe allergies should exercise caution. Always check labels and communicate with the chef regarding ingredients.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Privacy Policy',
              'We collect minimal data (Name, Email, Phone, Address) solely to facilitate food delivery. Your data is never sold to third parties.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Liability Note',
              'HomePlates is not liable for any direct or indirect damages resulting from the use of the platform or consumption of food ordered through it.',
            ),
            const SizedBox(height: 40),
            if (showAgreeButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.warmCharcoal,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('I AGREE TO ALL TERMS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey,
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }
}
