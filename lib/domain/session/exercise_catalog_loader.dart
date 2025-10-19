import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'exercise_catalog_loader_stub.dart'
    if (dart.library.io) 'exercise_catalog_loader_io.dart';

/// Loads the exercise catalog from the bundled assets with a simple
/// in-memory cache. If the asset is missing this will throw so callers
/// can surface a meaningful error rather than silently swapping data.
class ExerciseCatalogLoader {
  ExerciseCatalogLoader._();

  static final ExerciseCatalogLoader instance = ExerciseCatalogLoader._();

  static const String _assetPath = 'assets/data/exercises.json';

  List<Exercise>? _cache;

  Future<List<Exercise>> load() async {
    if (_cache != null) return _cache!;
    final raw = await _loadRawJson();
    _cache = _parseCatalog(raw);
    return _cache!;
  }

  void clearCache() {
    _cache = null;
  }

  Future<String> _loadRawJson() async {
    try {
      return await rootBundle.loadString(_assetPath);
    } on FlutterError catch (error, stackTrace) {
      final diskData = await loadExercisesFromDisk(_assetPath);
      if (diskData != null) {
        debugPrint(
          'ExerciseCatalogLoader: loaded $_assetPath from disk fallback '
          'after bundle error: $error',
        );
        debugPrint('$stackTrace');
        return diskData;
      }
      rethrow;
    }
  }

  List<Exercise> _parseCatalog(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    final exercises = decoded
        .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return exercises;
  }
}
