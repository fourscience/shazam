import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:test/test.dart';

import 'fakes/fake_operations_loader.dart';

void main() {
  test('Generator uses injected OperationsLoader', () async {
    final tempDir = await Directory.systemTemp.createTemp('generator_test_');
    addTearDown(() => tempDir.delete(recursive: true));

    final schemaPath = p.join(tempDir.path, 'schema.graphql');
    File(schemaPath).writeAsStringSync('type Query { noop: String }');
    final config = Config(
      outputDir: p.join(tempDir.path, 'out'),
      inputDir: tempDir.path,
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: false,
      schemaPath: schemaPath,
      scalarMapping: const {},
      configPath: 'config.yaml',
      keywordReplacements: const {},
      pluginPaths: const [],
    );

    final fakeLoader =
        FakeOperationsLoader(OperationsBundle(documents: const []));
    final renderer = FakeRenderer();
    final generator = Generator(
      config,
      operationsLoader: fakeLoader,
      renderer: renderer,
    );

    await generator.build();

    expect(fakeLoader.called, isTrue);
    expect(renderer.rendered, isFalse,
        reason: 'No operations should skip render');
  });
}
