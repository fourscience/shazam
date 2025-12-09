import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/shazam.dart';
import 'package:test/test.dart';

void main() {
  test('generates expected goldens', () async {
    final tempDir = await Directory.systemTemp.createTemp('shazam_golden_');
    final workdir = Directory(p.join(tempDir.path, 'spec_suite'))
      ..createSync(recursive: true);
    await _copyTree('spec_suite', workdir.path);

    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final outputRoot = p.join(workdir.path, 'generated');
    final config = Config(
      outputDir: outputRoot,
      inputDir: workdir.path,
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: true,
      schemaPath: p.join(workdir.path, 'schema.graphql'),
      scalarMapping: const {},
      configPath: 'config.yaml',
      keywordReplacements: const {},
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

    final schemaPath = p.join(workdir.path, 'schema.dart');
    final expectedSchema = File('spec_suite/schema.dart').readAsStringSync();
    expect(File(schemaPath).readAsStringSync(), expectedSchema);
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

Future<void> _copyTree(String src, String dest) async {
  final sourceDir = Directory(src);
  if (!sourceDir.existsSync()) return;
  await for (final entity in sourceDir.list(recursive: true)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: src);
    final target = File(p.join(dest, relative));
    target.parent.createSync(recursive: true);
    await entity.copy(target.path);
  }
}
