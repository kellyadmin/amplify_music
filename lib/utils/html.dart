// Conditional export: use real dart:html on web, otherwise use stub implementations
export 'html_stub.dart'
  if (dart.library.html) 'dart:html';
