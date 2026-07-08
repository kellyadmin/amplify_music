import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import '../constants.dart';
import '../widgets/gradient_text.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _logoAnimationController.forward();
    });

    Timer(const Duration(milliseconds: 1650), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: _buildPremiumLogo(),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: GradientText(
                      'Viba Music',
                      gradient: const LinearGradient(
                        colors: [textColor, primaryGradientEnd, primaryColor],
                      ),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _taglineFadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 1.4,
                        color: premiumGold.withOpacity(0.7),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'FEEL THE VIBE',
                        style: TextStyle(
                          color: premiumGold.withOpacity(0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 22,
                        height: 1.4,
                        color: premiumGold.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _taglineFadeAnimation,
                  child: _buildLoadingBar(),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBar() {
    return SizedBox(
      width: 140,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Container(color: Colors.white.withOpacity(0.08)),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryGradientEnd],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, Color(0xFF150F30), backgroundColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: _buildAnimatedOrb(
              size: 320,
              color: primaryColor.withOpacity(0.20),
              duration: const Duration(seconds: 9),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: _buildAnimatedOrb(
              size: 360,
              color: primaryGradientEnd.withOpacity(0.16),
              duration: const Duration(seconds: 12),
            ),
          ),
          Positioned(
            top: 220,
            left: -60,
            child: _buildAnimatedOrb(
              size: 180,
              color: premiumGold.withOpacity(0.08),
              duration: const Duration(seconds: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedOrb({
    required double size,
    required Color color,
    required Duration duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 2 * math.pi),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(math.sin(value) * 22, math.cos(value) * 22),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 70, spreadRadius: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryGradientEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.55),
                  blurRadius: 44,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: premiumGold.withOpacity(0.22),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(
                color: premiumGold.withOpacity(0.35),
                width: 1.4,
              ),
            ),
            padding: const EdgeInsets.all(30),
            child: Image.asset(
              'assets/icon/icon_foreground.png',
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
