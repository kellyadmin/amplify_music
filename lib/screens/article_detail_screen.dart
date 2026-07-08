import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_article.dart';
import '../constants.dart';

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;
  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  String _formatDate(String pubDate) {
    final dateTime = DateTime.tryParse(pubDate);
    if (dateTime == null) return '';
    const monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${monthNames[dateTime.month]} ${dateTime.day}, ${dateTime.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: secondaryColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: cardColor,
                      child: const Icon(Icons.broken_image, size: 60, color: subtitleColor),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, secondaryColor],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.source, color: subtitleColor, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          article.source,
                          style: const TextStyle(color: subtitleColor, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, color: subtitleColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(article.pubDate),
                        style: const TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (article.aiSummary.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: primaryColor, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'AI Generated Summary',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            article.aiSummary,
                            style: const TextStyle(color: textColor, fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(article.link);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: kIsWeb ? LaunchMode.externalApplication : LaunchMode.inAppWebView,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Read Full Story'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
