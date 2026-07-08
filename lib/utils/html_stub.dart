// Minimal stub implementation of a subset of dart:html API used by the app.
// These implementations are no-ops or lightweight placeholders so mobile builds
// (Android/iOS) can compile. They do not provide real browser functionality.

class MetaElement {
  String content = '';
}

class Element {
  void append(dynamic _) {}
  void remove() {}
}

class BodyElement extends Element {}

class Document {
  String title = '';
  BodyElement? body;

  dynamic querySelector(String _) => null;

  void execCommand(String _) {}
}

final Document document = Document();

class Window {
  void open(String _, String __) {}
}

final Window window = Window();

class Blob {
  Blob(List<dynamic> parts, String type);
}

class Url {
  static String createObjectUrlFromBlob(Blob _) => '';
  static void revokeObjectUrl(String _) {}
}

class AnchorElement extends Element {
  AnchorElement({String? href});
  String? href;
  void setAttribute(String _, String __) {}
  void click() {}
}

class HttpRequestResponse {
  int status = 200;
  String? responseText;
}

class HttpRequest {
  static Future<HttpRequestResponse> request(String url, {String method = 'GET'}) async {
	// Return an empty successful response; real network calls should use package:http or dio
	return HttpRequestResponse()..status = 200..responseText = '';
  }
}

class TextAreaElement extends Element {
  String value = '';
  void select() {}
}
