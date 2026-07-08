import 'html.dart' as html;

import '../models.dart';

// This helper function dynamically updates the page's SEO tags.
void updateSongSeo(Song song) {
  // We use dart:html to directly access and modify the Document Object Model (DOM).

  // 1. Update the page title
  html.document.title = '${song.title} by ${song.artist} on Viba Music';

  // 2. Find and update the meta description tag
  // We check if the tag exists before trying to update its content.
  final metaDescription = html.document.querySelector('meta[name="description"]');
  if (metaDescription is html.MetaElement) {
    metaDescription.content = 'Listen to "${song.title}" by ${song.artist} on the official Amplify Music platform.';
  }

  // 3. Update the Open Graph title (for social media sharing)
  final ogTitle = html.document.querySelector('meta[property="og:title"]');
  if (ogTitle is html.MetaElement) {
    ogTitle.content = '${song.title} by ${song.artist}';
  }

  // 4. Update the Open Graph description
  final ogDescription = html.document.querySelector('meta[property="og:description"]');
  if (ogDescription is html.MetaElement) {
    ogDescription.content = 'Listen to "${song.title}" on Amplify Music.';
  }

  // 5. Update the Open Graph image (the album art thumbnail)
  final ogImage = html.document.querySelector('meta[property="og:image"]');
  if (ogImage is html.MetaElement) {
    ogImage.content = song.albumArtUrl;
  }
}
