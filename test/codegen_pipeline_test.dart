import 'dart:io';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:shazam/src/codegen_pipeline.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/document_ir.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:shazam/src/renderer.dart';
import 'package:test/test.dart';
import 'package:code_builder/code_builder.dart';

Config _config(String schemaPath, String inputDir) => Config(
      outputDir: 'out',
      inputDir: inputDir,
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: false,
      schemaPath: schemaPath,
      scalarMapping: const {},
      configPath: 'config.yaml',
      keywordReplacements: const {},
      pluginPaths: const [],
      logLevel: LogLevel.info,
    );

class _FakeRenderer implements Renderer {
  DocumentIr? lastIr;
  Config? lastConfig;
  List<PluginRegistration>? lastPlugins;

  @override
  Future<void> render(
      DocumentIr ir, Config config, List<PluginRegistration> plugins) async {
    lastIr = ir;
    lastConfig = config;
    lastPlugins = plugins;
  }
}

class _FakeLoader implements OperationsLoader {
  _FakeLoader(this.bundle);
  final OperationsBundle bundle;

  @override
  String get inputDir => '';

  @override
  Future<OperationsBundle> load() async => bundle;
}

class _DummyPlugin implements GeneratorPlugin {
  const _DummyPlugin();
  @override
  void onDocument(CodegenContext ctx) {}

  @override
  void onLibrary(LibraryBuilder library, CodegenContext ctx) {}

  @override
  void onRenderComplete(CodegenContext ctx) {}
}

const _dummyRegistration = PluginRegistration(
  plugin: _DummyPlugin(),
  manifest: PluginManifest(id: 'dummy', version: '0.0.0'),
);

DocumentSource _docSource(String text, {String path = 'ops.graphql'}) =>
    DocumentSource(path: path, document: parseString(text));

void main() {
  test('loadSchema throws when schema is missing', () async {
    final cfg = _config('/tmp/not_found.graphql', 'lib');
    final pipeline = CodegenPipeline(
      config: cfg,
      renderer: _FakeRenderer(),
      plugins: const [],
      cache: IrCache(),
    );

    expect(pipeline.loadSchema(), throwsStateError);
  });

  test('mergeDocuments combines definitions preserving path', () {
    final cfg = _config('schema.graphql', 'lib');
    final pipeline = CodegenPipeline(
      config: cfg,
      renderer: _FakeRenderer(),
      plugins: const [],
      cache: IrCache(),
    );
    final first = _docSource('query A { __typename }', path: 'a.graphql');
    final second = _docSource('fragment Foo on Query { __typename }',
        path: 'b.graphql');

    final merged = pipeline.mergeDocuments([first, second]);

    expect(merged.path, cfg.schemaPath);
    expect(merged.document.definitions, hasLength(2));
    expect(
        merged.document.definitions.whereType<OperationDefinitionNode>(),
        hasLength(1));
    expect(merged.document.definitions.whereType<FragmentDefinitionNode>(),
        hasLength(1));
  });

  test('render delegates to renderer with provided plugins', () async {
    final tempDir = await Directory.systemTemp.createTemp('pipeline_');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
    final schemaPath = File('${tempDir.path}/schema.graphql')
      ..writeAsStringSync('type Query { noop: String }');
    final cfg = _config(schemaPath.path, tempDir.path);
    final renderer = _FakeRenderer();
    final pipeline = CodegenPipeline(
      config: cfg,
      renderer: renderer,
      plugins: const [_dummyRegistration],
      cache: IrCache(),
      operationsLoader: _FakeLoader(OperationsBundle(documents: const [])),
    );
    final ir = DocumentIr(
      path: 'doc.graphql',
      operations: const [],
      fragments: const [],
      records: const [],
      interfaceImplementations: const {},
      unionVariants: const {},
      enums: const [],
    );

    await pipeline.render(ir);

    expect(renderer.lastIr, equals(ir));
    expect(renderer.lastConfig, equals(cfg));
    expect(renderer.lastPlugins, hasLength(1));
  });
}
