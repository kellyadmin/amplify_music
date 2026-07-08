import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/vibrant_card.dart';
import '../widgets/animated_gradient_background.dart';

/// Showcase screen demonstrating all new vibrant components
/// Copy elements from here to your actual screens!
class VibrantShowcaseScreen extends StatelessWidget {
  const VibrantShowcaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => brandGradient.createShader(bounds),
          child: Text(
            'Vibrant UI Showcase',
            style: homeFont(
              size: 20,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Animated Background
            _buildHeroSection(),
            
            SizedBox(height: spacingSectionLg),
            
            // Buttons Section
            _buildSectionTitle('Vibrant Buttons'),
            SizedBox(height: spacingLg),
            _buildButtonsSection(),
            
            SizedBox(height: spacingSectionLg),
            
            // Cards Section
            _buildSectionTitle('Vibrant Cards'),
            SizedBox(height: spacingLg),
            _buildCardsSection(),
            
            SizedBox(height: spacingSectionLg),
            
            // Glassmorphic Section
            _buildSectionTitle('Glassmorphic Cards'),
            SizedBox(height: spacingLg),
            _buildGlassmorphicSection(),
            
            SizedBox(height: spacingSectionLg),
            
            // Play Button Section
            _buildSectionTitle('Pulsing Glow Effects'),
            SizedBox(height: spacingLg),
            _buildPlayButtonsSection(),
            
            SizedBox(height: spacingSectionLg),
            
            // Stats Cards
            _buildSectionTitle('Stats Cards'),
            SizedBox(height: spacingLg),
            _buildStatsSection(),
            
            SizedBox(height: spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => brandGradient.createShader(bounds),
      child: Text(
        title,
        style: homeFont(
          size: 18,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedGradientBackground(
      colors: [accentPurple, accentColor, neonBlue, accentMint],
      opacity: 0.15,
      duration: Duration(seconds: 8),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => brandGradient.createShader(bounds),
              child: Text(
                'Discover New Music',
                style: homeFont(
                  size: 28,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Personalized just for you with AI',
              style: homeFont(size: 15, color: subtitleColor),
            ),
            SizedBox(height: 20),
            VibrantButton(
              text: 'Explore Now',
              icon: Icons.explore_rounded,
              gradient: brandGradient,
              width: double.infinity,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        VibrantButton(
          text: 'Brand Gradient',
          icon: Icons.star_rounded,
          gradient: brandGradient,
          width: double.infinity,
          onPressed: () {},
        ),
        SizedBox(height: 12),
        VibrantButton(
          text: 'Premium',
          icon: Icons.diamond_rounded,
          gradient: premiumGradient,
          width: double.infinity,
          onPressed: () {},
        ),
        SizedBox(height: 12),
        VibrantButton(
          text: 'Action',
          icon: Icons.favorite_rounded,
          gradient: actionGradient,
          width: double.infinity,
          onPressed: () {},
        ),
        SizedBox(height: 12),
        VibrantButton(
          text: 'Success',
          icon: Icons.check_circle_rounded,
          gradient: mintGradient,
          width: double.infinity,
          onPressed: () {},
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: VibrantButton(
                text: 'Neon',
                gradient: neonGradient,
                height: 44,
                onPressed: () {},
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: VibrantButton(
                text: 'Fire',
                gradient: fireGradient,
                height: 44,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Row(
      children: [
        Expanded(
          child: VibrantCard(
            gradient: neonGradient,
            enableGlow: true,
            enableAnimation: true,
            child: Column(
              children: [
                Icon(Icons.music_note_rounded, color: textColor, size: 32),
                SizedBox(height: 12),
                Text(
                  'Neon Card',
                  style: homeFont(size: 14, weight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Animated glow',
                  style: homeFont(size: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: VibrantCard(
            gradient: cosmicGradient,
            enableGlow: true,
            enableAnimation: true,
            child: Column(
              children: [
                Icon(Icons.stars_rounded, color: textColor, size: 32),
                SizedBox(height: 12),
                Text(
                  'Cosmic Card',
                  style: homeFont(size: 14, weight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Premium feel',
                  style: homeFont(size: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphicSection() {
    return Column(
      children: [
        GlassmorphicCard(
          borderColor: accentColor.withOpacity(0.4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: actionGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_rounded, color: textColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liked Songs',
                      style: homeFont(size: 15, weight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '142 songs',
                      style: homeFont(size: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: subtitleColor, size: 16),
            ],
          ),
        ),
        SizedBox(height: 12),
        GlassmorphicCard(
          borderColor: accentPurple.withOpacity(0.4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: premiumGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.diamond_rounded, color: textColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Features',
                      style: homeFont(size: 15, weight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Unlock now',
                      style: homeFont(size: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: subtitleColor, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButtonsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PulsingGlow(
          color: accentMint,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: mintGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: textColor, size: 32),
          ),
        ),
        PulsingGlow(
          color: accentColor,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: actionGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: textColor, size: 28),
          ),
        ),
        PulsingGlow(
          color: accentPurple,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: premiumGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, color: textColor, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: VibrantCard(
            gradient: electricGradient,
            enableGlow: true,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => electricGradient.createShader(bounds),
                  child: Text(
                    '1.2K',
                    style: homeFont(
                      size: 28,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Songs',
                  style: homeFont(size: 12, color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: VibrantCard(
            gradient: fireGradient,
            enableGlow: true,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => fireGradient.createShader(bounds),
                  child: Text(
                    '45',
                    style: homeFont(
                      size: 28,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Artists',
                  style: homeFont(size: 12, color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
