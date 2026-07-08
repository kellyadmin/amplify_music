import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF171514),
                const Color(0xFF2A2A2A),
                const Color(0xFF171514),
              ],
              stops: [
                0.0,
                _animation.value.clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerSongCard extends StatelessWidget {
  const ShimmerSongCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerLoading(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 14,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
          const ShimmerLoading(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ],
      ),
    );
  }
}

class ShimmerAlbumCard extends StatelessWidget {
  const ShimmerAlbumCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(
            width: 160,
            height: 160,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(height: 12),
          const ShimmerLoading(
            width: 120,
            height: 14,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 6),
          ShimmerLoading(
            width: 80,
            height: 12,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

class ShimmerPlaylistCard extends StatelessWidget {
  const ShimmerPlaylistCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(
            width: 180,
            height: 180,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(height: 12),
          const ShimmerLoading(
            width: 140,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 6),
          ShimmerLoading(
            width: 100,
            height: 12,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

class ShimmerArtistCard extends StatelessWidget {
  const ShimmerArtistCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          const ShimmerLoading(
            width: 120,
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(60)),
          ),
          const SizedBox(height: 12),
          ShimmerLoading(
            width: 100,
            height: 14,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}
