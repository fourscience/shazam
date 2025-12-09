import 'dart:io';

import 'package:gql/ast.dart';

import 'builders/document_ir_builder.dart';
import 'builders/ir_context.dart';
import 'config.dart';
import 'ir.dart';
import 'log.dart';
import 'operations.dart';
import 'plugin.dart';
import 'renderer.dart';
import 'schema.dart';
import 'schema_index.dart';

/// Top-level coordinator that parses GraphQL sources, builds IR, and renders code.
class Generator {
  Generator(
    this.config, {
    List<GeneratorPlugin>? plugins,
    Renderer? renderer,
    IrCache? cache,
  })  : plugins = plugins ?? [],
        renderer = renderer ?? CodeRenderer(config),
        cache = cache ?? IrCache();

  final Config config;
  final List<GeneratorPlugin> plugins;
  final Renderer renderer;
  final IrCache cache;

  Future<void> build() async {
    final schemaFile = File(config.schemaPath);
    if (!schemaFile.existsSync()) {
      throw StateError('Schema file not found at ${config.schemaPath}');
    }
    final schemaSource = await schemaFile.readAsString();
    final schema = Schema.parse(schemaSource);
    final schemaIndex = SchemaIndex(schema);

    final operations = await OperationsLoader(inputDir: config.inputDir).load();

    if (operations.documents.isEmpty) {
      logWarn('No operations found under ${config.inputDir}; nothing to do');
      return;
    }

    final merged = _mergeDocuments(operations.documents);

    final context = IrBuildContext(
      config: config,
      schema: schema,
      schemaIndex: schemaIndex,
      cache: cache,
    );
    final ir = DocumentIrBuilder(context).build(merged);
    await renderer.render(ir, config, plugins);

    logInfo('Build completed');
  }

  DocumentSource _mergeDocuments(List<DocumentSource> sources) {
    final defs = <DefinitionNode>[];
    for (final src in sources) {
      defs.addAll(src.document.definitions);
    }
    final basePath = sources.first.path;
    final mergedDoc = DocumentNode(definitions: defs);
    return DocumentSource(path: basePath, document: mergedDoc);
  }
}
