import 'dart:io';

Future<String?> loadExercisesFromDisk(String assetPath) async {
  final file = File(assetPath);
  if (!await file.exists()) return null;
  return file.readAsString();
}
