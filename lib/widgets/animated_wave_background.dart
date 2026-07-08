import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWaveBackground extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final List<Color>? colors;

  const AnimatedWaveBackground({
    Key? key,
    required this.child,
    this.isActive = true,
    this.colors,
  }) : super(key: key);

  @override
  State<AnimatedWaveBackground> createState() => _AnimatedWaveBackgroundState();
}

class _AnimatedWaveBackgroundState extends State<AnimatedWaveBackground>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _colorController;
  late Animation<double> _waveAnimation;
  late Animation<double> _colorAnimation;

  // Predefined gradient sets for dynamic backgrounds
  final List<List<Color>> _gradientSets = [
    [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)], // Deep blue
    [const Color(0xFF2D1B69), const Color(0xFF11175B), const Color(0xFF0A0A0B)], // Purple night  
    [const Color(0xFF1F1C2C), const Color(0xFF928DAB), const Color(0xFF2C3E50)], // Silver mist
    [const Color(0xFF134E5E), const Color(0xFF71B280), const Color(0xFF2C5530)], // Ocean depths
    [const Color(0xFF2C3E50), const Color(0xFF3498DB), const Color(0xFF1A252F)], // Midnight blue
  ];

  int _currentGradientIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Color transition controller  
    _colorController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _colorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _waveController.repeat();
    _colorController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentGradientIndex = (_currentGradientIndex + 1) % _gradientSets.length;
        });
        _colorController.reset();
        _colorController.forward();
      }
    });
    _colorController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColors = widget.colors ?? _gradientSets[_currentGradientIndex];
            final nextColors = widget.colors ?? _gradientSets[(_currentGradientIndex + 1) % _gradientSets.length];
            
            final interpolatedColors = List.generate(3, (index) {
              return Color.lerp(
                currentColors[index % currentColors.length],
                nextColors[index % nextColors.length],
                _colorAnimation.value,
              )!;
            });

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: interpolatedColors,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Animated waves
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: WavePainter(
                animationValue: _waveAnimation.value,
                isActive: widget.isActive,
              ),
            );
          },
        ),
        
        // Content overlay
        widget.child,
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isActive;

  WavePainter({
    required this.animationValue,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = const Color(0xFFF2B84B).withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw multiple wave layers
    _drawWave(canvas, size, paint1, animationValue, 0.8, 40.0);
    _drawWave(canvas, size, paint2, animationValue + math.pi / 3, 1.2, 60.0);
    _drawWave(canvas, size, paint3, animationValue + math.pi / 6, 1.0, 80.0);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double phase, double frequency, double amplitude) {
    final path = Path();
    final waveHeight = size.height * 0.7;
    
    path.moveTo(0, waveHeight);
    
    for (double x = 0; x <= size.width; x += 1) {
      final normalizedX = x / size.width;
      final y = waveHeight + 
                 math.sin((normalizedX * 2 * math.pi * frequency) + phase) * amplitude +
                 math.sin((normalizedX * 4 * math.pi * frequency) + (phase * 1.5)) * (amplitude * 0.5) +
                 math.sin((normalizedX * 6 * math.pi * frequency) + (phase * 2)) * (amplitude * 0.3);
      
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Floating particles widget
class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double maxSize;
  final double minSize;

  const FloatingParticles({
    Key? key,
    this.particleCount = 20,
    this.particleColor = Colors.white,
    this.maxSize = 4.0,
    this.minSize = 1.0,
  }) : super(key: key);

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    // Initialize particles
    final random = math.Random();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: widget.minSize + random.nextDouble() * (widget.maxSize - widget.minSize),
        speedX: (random.nextDouble() - 0.5) * 0.02,
        speedY: (random.nextDouble() - 0.5) * 0.02,
        opacity: 0.1 + random.nextDouble() * 0.4,
      ));
    }

    _controller.addListener(_updateParticles);
    _controller.repeat();
  }

  void _updateParticles() {
    for (final particle in _particles) {
      particle.x += particle.speedX;
      particle.y += particle.speedY;

      // Wrap around edges
      if (particle.x > 1.0) particle.x = 0.0;
      if (particle.x < 0.0) particle.x = 1.0;
      if (particle.y > 1.0) particle.y = 0.0;
      if (particle.y < 0.0) particle.y = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(
            particles: _particles,
            color: widget.particleColor,
          ),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Ripple effect widget for interactive elements
class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;

  const RippleEffect({
    Key? key,
    required this.child,
    this.onTap,
    this.rippleColor = Colors.white,
  }) : super(key: key);

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _rippleController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: AnimatedBuilder(
        animation: _rippleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _tapPosition != null
                ? RipplePainter(
                    center: _tapPosition!,
                    progress: _rippleAnimation.value,
                    color: widget.rippleColor,
                  )
                : null,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final Color color;

  RipplePainter({
    required this.center,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity((1.0 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final radius = progress * (size.width > size.height ? size.width : size.height);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
