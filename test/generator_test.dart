import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator.dart';
import 'package:shazam/src/ir.dart';
import 'package:shazam/src/operations.dart';
import 'package:shazam/src/plugin.dart';
import 'package:shazam/src/renderer.dart';

class _FakeOperationsLoader implements OperationsLoader {
  _FakeOperationsLoader(this.bundle);
  final OperationsBundle bundle;
  bool called = false;
  @override
  String get inputDir => '';

  @override
  Future<OperationsBundle> load() async {
    called = true;
    return bundle;
  }
}

class _FakeRenderer implements Renderer {
  bool rendered = false;
  @override
  Future<void> render(
      DocumentIr ir, Config config, List<GeneratorPlugin> plugins) async {
    rendered = true;
  }
}

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
        _FakeOperationsLoader(OperationsBundle(documents: const []));
    final renderer = _FakeRenderer();
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
