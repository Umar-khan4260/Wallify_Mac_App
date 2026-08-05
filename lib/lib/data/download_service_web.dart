/// Web stub — file saving is a no-op on web.
Future<void> saveFile(String fileName, List<int> bytes) async {
  // Web doesn't support local file system access the same way.
  // The download metadata is stored in SharedPreferences instead.
}
