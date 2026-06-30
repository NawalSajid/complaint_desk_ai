import 'download_helper_io.dart'
    if (dart.library.html) 'download_helper_web.dart' as platform;

/// Saves [bytes] as [filename].
/// On mobile/desktop: writes to app documents dir, returns the file path.
/// On web: triggers a browser download, returns the filename.
Future<String> saveAndDownload({
  required List<int> bytes,
  required String filename,
}) {
  return platform.saveAndDownload(bytes: bytes, filename: filename);
}