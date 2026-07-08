import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class PremiumLoadingScreen extends StatefulWidget {
  final String? message;
  final double? progress;
  final bool showProgress;

  const PremiumLoadingScreen({
    Key? key,
    this.message,
    this.progress,
    this.showProgress = false,
  }) : super(key: key);

  @override
  State<PremiumLoadingScreen> createState() => _PremiumLoadingScreenState();
}

class _PremiumLoadingScreenState extends State<PremiumLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium loader animation
                    _buildPremiumLoader(),
                    const SizedBox(height: 48),
                    // Loading message
                    if (widget.message != null) _buildLoadingMessage(),
                    const SizedBox(height: 24),
                    // Progress indicator
                    if (widget.showProgress && widget.progress != null)
                      _buildProgressBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A0B),
            const Color(0xFF1A1F3A).withOpacity(0.5),
            const Color(0xFF0A0A0B),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated orbs
          Positioned(
            top: -100,
            right: -100,
            child: _buildAnimatedOrb(
              size: 300,
              color: const Color(0xFFF2B84B).withOpacity(0.1),
              duration: const Duration(seconds: 8),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildAnimatedOrb(
              size: 350,
              color: const Color(0xFFF2B84B).withOpacity(0.08),
              duration: const Duration(seconds: 10),
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
          offset: Offset(
            math.sin(value) * 20,
            math.cos(value) * 20,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumLoader() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 2 * math.pi),
            duration: const Duration(seconds: 3),
            curve: Curves.linear,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF2B84B).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner rotating ring (opposite direction)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: -2 * math.pi),
            duration: const Duration(seconds: 4),
            curve: Curves.linear,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF2B84B).withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          // Center logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF2B84B),
                  const Color(0xFFF2B84B).withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF2B84B).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note,
              color: Color(0xFF0A0A0B),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Column(
      children: [
        Text(
          widget.message ?? 'Loading...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Preparing your musical experience',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: widget.progress,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8901F)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${(widget.progress! * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
