import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/shazam.dart';
import 'package:test/test.dart';

void main() {
  test('generates expected goldens', () async {
    final tempDir = await Directory.systemTemp.createTemp('shazam_golden_');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final outputRoot = p.join(tempDir.path, 'generated');
    final config = Config(
      outputDir: outputRoot,
      inputDir: 'spec_suite',
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: true,
      schemaPath: 'spec_suite/schema.graphql',
      scalarMapping: const {},
      configPath: 'config.yaml',
    );

    final generator = Generator(config);
    await generator.build();

    final actualFiles = _collectFiles(outputRoot);
    final expectedFiles = _collectFiles('spec_suite/generated');

    expect(actualFiles.keys, unorderedEquals(expectedFiles.keys));
    for (final path in expectedFiles.keys) {
      expect(actualFiles[path], expectedFiles[path],
          reason: 'Mismatch in $path');
    }
  });
}

Map<String, String> _collectFiles(String root) {
  final result = <String, String>{};
  if (!Directory(root).existsSync()) return result;

  for (final entity in Directory(root).listSync(recursive: true)) {
    if (entity is! File) continue;
    if (entity.path.endsWith('.raw')) continue;
    final rel = p.relative(entity.path, from: root);
    result[rel] = entity.readAsStringSync();
  }
  return result;
}
