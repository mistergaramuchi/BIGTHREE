import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/domain/session/exercise_catalog_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads catalog from assets', () async {
    final data = await ExerciseCatalogLoader.instance.load();
    expect(data, isNotEmpty);
  });
}
