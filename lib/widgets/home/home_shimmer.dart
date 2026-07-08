import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants.dart';

class HomeShimmerSongCard extends StatelessWidget {
  const HomeShimmerSongCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: songCardWidth,
      margin: const EdgeInsets.only(right: 14),
      child: Shimmer.fromColors(
        baseColor: cardColor,
        highlightColor: surfaceElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 158,
              width: songCardWidth,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 132,
              height: 14,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 96,
              height: 12,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShimmerNewsCard extends StatelessWidget {
  const HomeShimmerNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: cardColor,
        highlightColor: secondaryColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: 250,
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 220,
                    height: 14,
                    color: secondaryColor.withOpacity(0.8),
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  Container(
                    width: 150,
                    height: 14,
                    color: secondaryColor.withOpacity(0.8),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class HomeShimmerArtistCard extends StatelessWidget {
  const HomeShimmerArtistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 16,
            color: secondaryColor.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}

class HomeShimmerPlaylistCard extends StatelessWidget {
  const HomeShimmerPlaylistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: secondaryColor.withOpacity(0.8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  color: secondaryColor.withOpacity(0.8),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 70,
                  height: 12,
                  color: secondaryColor.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeVerticalSongListShimmer extends StatelessWidget {
  const HomeVerticalSongListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: cardColor,
      highlightColor: secondaryColor,
      child: Column(
        children: List.generate(5, (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          padding: const EdgeInsets.all(12.0),
          height: 80,
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ),
    );
  }
}
