import 'dart:typed_data';

// Minimal stub for package:file_picker used where plugin is not available.

class PlatformFile {
  final String name;
  final Uint8List? bytes;
  final String? path;
  final int? size;

  PlatformFile({required this.name, this.bytes, this.path, this.size});
}

class FilePickerResult {
  final List<PlatformFile> files;
  FilePickerResult(this.files);
}

class _FilePickerPlatform {
  Future<FilePickerResult?> pickFiles({
	bool allowMultiple = false,
	bool withData = false,
	FileType type = FileType.any,
	List<String>? allowedExtensions,
  }) async {
	// Not supported on non-desktop platforms in the stub; return null.
	return null;
  }
}

class FilePicker {
  static final _FilePickerPlatform platform = _FilePickerPlatform();
}

enum FileType { any, audio, image, video, custom }
