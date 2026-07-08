import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';

class BannerItem {
  final String id;
  final String imageUrl;
  final String link;
  BannerItem({required this.id, required this.imageUrl, required this.link});
  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      id: map['id']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      link: map['link']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {'id': id, 'image_url': imageUrl, 'link': link};
  }
}

class HomeBannersSection extends StatefulWidget {
  final List<BannerItem> banners;
  const HomeBannersSection({Key? key, required this.banners}) : super(key: key);

  @override
  State<HomeBannersSection> createState() => _HomeBannersSectionState();
}

class _HomeBannersSectionState extends State<HomeBannersSection> {
  late PageController _pageController;
  int _currentBanner = 0;
  Timer? _bannerTimer;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(HomeBannersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.isEmpty && oldWidget.banners.isNotEmpty) {
      _bannerTimer?.cancel();
    } else if (widget.banners.isNotEmpty && oldWidget.banners.isEmpty) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _bannerTimer?.cancel();
    if (widget.banners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isInteracting || !_pageController.hasClients) return;
      final next = (_currentBanner + 1) % widget.banners.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: spacingXl),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                margin: const EdgeInsets.only(right: spacingMd),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryColor, Color(0xFFE63950)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.auto_awesome_rounded,
                  color: primaryColor, size: 18),
              const SizedBox(width: spacingSm),
              Text('Amplify picks',
                  style: homeFont(size: headingLg, weight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: spacingMd),
        SizedBox(
          height: 164,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentBanner = index);
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: spacingXl),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isInteracting = true),
                  onTapUp: (_) async {
                    setState(() => _isInteracting = false);
                    final url = Uri.parse(banner.link);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  onTapCancel: () => setState(() => _isInteracting = false),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.65)
                                ],
                                stops: const [0.45, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('Explore now',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Colors.white.withOpacity(0.9))),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded,
                                      color: secondaryColor, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: spacingMd),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: widget.banners.length,
            effect: const ExpandingDotsEffect(
              activeDotColor: primaryColor,
              dotColor: subtitleColor,
              dotHeight: 8,
              dotWidth: 8,
            ),
          ),
        ),
        const SizedBox(height: spacingXl),
      ],
    );
  }
}
