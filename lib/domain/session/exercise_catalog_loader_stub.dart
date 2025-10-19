import 'package:flutter/foundation.dart';

Future<String?> loadExercisesFromDisk(String assetPath) async {
  debugPrint(
    'ExerciseCatalogLoader: disk fallback not supported on this platform. '
    'Missing asset: $assetPath',
  );
  return null;
}
