class BannerItem {
  final String imageUrl;
  final String linkType;
  final String linkId;

  BannerItem({
    required this.imageUrl,
    required this.linkType,
    required this.linkId,
  });

  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      imageUrl: map['image_url'] ?? '',
      linkType: map['link_type'] ?? '',
      linkId: map['link_id'] ?? '',
    );
  }
}
