import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payments_screen.dart';

import '../constants.dart';
// Constants matching home_screen.dart
const Color primaryColor = Color(0xFFF2B84B);
const Color secondaryColor = Color(0xFF0A0A0B);
const Color cardColor = Color(0xFF171514);
const Color textColor = Colors.white;
const Color subtitleColor = Colors.white70;

class PremiumSubscriptionPage extends StatelessWidget {
  const PremiumSubscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(
          'Amplify Premium',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        backgroundColor: secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: primaryColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock unlimited music, ad-free listening, and exclusive features',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Features List
            Text(
              'Premium Features',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._buildFeaturesList(),
            
            const SizedBox(height: 32),
            
            // Pricing Plans
            Text(
              'Choose Your Plan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPricingCard(
              context,
              title: 'Monthly Premium',
              price: '\$9.99',
              period: 'per month',
              features: [
                'Unlimited skips',
                'Ad-free listening',
                'Offline downloads',
                'High-quality audio',
              ],
              isPopular: false,
            ),
            
            const SizedBox(height: 16),
            
            _buildPricingCard(
              context,
              title: 'Annual Premium',
              price: '\$99.99',
              period: 'per year',
              features: [
                'All monthly features',
                'Save 2 months',
                'Exclusive content',
                'Priority support',
              ],
              isPopular: true,
            ),
            
            const SizedBox(height: 20),
            
            // Terms
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '7-day free trial • Cancel anytime • Terms apply\nSecure payments powered by Pesapal & PayPal',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildFeaturesList() {
    final features = [
      {'icon': Icons.skip_next, 'title': 'Unlimited Skips', 'desc': 'Skip as many songs as you want'},
      {'icon': Icons.block, 'title': 'Ad-Free Listening', 'desc': 'Enjoy uninterrupted music'},
      {'icon': Icons.download, 'title': 'Offline Downloads', 'desc': 'Listen anywhere, anytime'},
      {'icon': Icons.high_quality, 'title': 'High-Quality Audio', 'desc': 'Crystal clear sound quality'},
      {'icon': Icons.auto_awesome, 'title': 'AI Recommendations', 'desc': 'Personalized daily mixes'},
      {'icon': Icons.star, 'title': 'Exclusive Content', 'desc': 'Access to premium tracks'},
    ];
    
    return features.map((feature) => _buildFeatureItem(
      feature['icon'] as IconData,
      feature['title'] as String,
      feature['desc'] as String,
    )).toList();
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
  }) {
    // Extract numeric amount from price string
    final numericAmount = double.parse(price.replaceAll('\$', ''));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: primaryColor, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: isPopular ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'MOST POPULAR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                ),
              ),
            ),
          if (isPopular) const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  period,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 24),
          // Individual Subscribe Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentsScreen(
                      planType: title.replaceAll(' Premium', ''),
                      amount: numericAmount,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? primaryColor : Colors.transparent,
                foregroundColor: isPopular ? secondaryColor : primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isPopular ? BorderSide.none : const BorderSide(
                    color: primaryColor,
                    width: 1.5,
                  ),
                ),
                elevation: isPopular ? 4 : 0,
              ),
              child: Text(
                isPopular ? 'Choose Plan' : 'Select Plan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Coming Soon!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        content: Text(
          'Premium subscriptions will be available soon. Stay tuned for updates!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: subtitleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
