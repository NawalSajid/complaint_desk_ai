import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to a temp file, then opens the native share sheet so the
/// user can save it to Downloads/Files, send it via email, etc.
///
/// Writing straight to getApplicationDocumentsDirectory() (the old approach)
/// put the file in the app's private sandbox — invisible to the user and
/// inaccessible without a rooted file manager. That's why "download" looked
/// like it did nothing on mobile even though the write succeeded. Routing
/// through the share sheet sidesteps Android's messy scoped-storage/
/// permission requirements entirely and works the same way on iOS.
Future<String> saveAndDownload({
  required List<int> bytes,
  required String filename,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);

  final mimeType = _mimeTypeFor(filename);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType, name: filename)],
    subject: filename,
    text: 'ComplaintDesk.AI export: $filename',
  );

  return file.path;
}

String? _mimeTypeFor(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'csv':
      return 'text/csv';
    case 'pdf':
      return 'application/pdf';
    default:
      return null;
  }
}