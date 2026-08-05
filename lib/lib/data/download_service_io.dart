import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Saves bytes to the app's documents directory under a Wallify sub-folder.
Future<void> saveFile(String fileName, List<int> bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final wallifyDir = Directory('${dir.path}/Wallify');
  if (!await wallifyDir.exists()) {
    await wallifyDir.create(recursive: true);
  }
  final baseName = fileName.split('/').last;
  final file = File('${wallifyDir.path}/$baseName');
  await file.writeAsBytes(bytes);
}
