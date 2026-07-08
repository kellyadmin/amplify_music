// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PlatformUtils {
  static void openPopup(String url) {
    html.window.open(url, '_blank');
  }

  static void downloadFile(List<int> bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
