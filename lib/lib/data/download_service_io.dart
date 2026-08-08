import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [bytes] to disk and returns true on success.
///
/// On desktop (macOS, Windows, Linux) the user is asked where to save
/// (defaulting to their Downloads folder). On mobile the bytes are written
/// to the app's documents directory under a Wallify sub-folder.
Future<bool> saveFile(String fileName, List<int> bytes) async {
  final baseName = fileName.split('/').last;
  final extension = baseName.contains('.') ? baseName.split('.').last : 'jpg';

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    final location = await getSaveLocation(
      suggestedName: baseName,
      acceptedTypeGroups: [
        XTypeGroup(label: 'Image', extensions: [extension]),
      ],
    );
    if (location == null) return false; // User cancelled the save dialog.
    await File(location.path).writeAsBytes(bytes);
    return true;
  }

  final dir = await getApplicationDocumentsDirectory();
  final wallifyDir = Directory('${dir.path}/Wallify');
  if (!await wallifyDir.exists()) {
    await wallifyDir.create(recursive: true);
  }
  final file = File('${wallifyDir.path}/$baseName');
  await file.writeAsBytes(bytes);
  return true;
}
