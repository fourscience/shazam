import 'dart:io';

import 'package:gql/ast.dart';

import 'builders/document_ir_builder.dart';
import 'builders/ir_context.dart';
import 'config.dart';
import 'ir.dart';
import 'operations.dart';
import 'plugin.dart';
import 'renderer.dart';
import 'schema.dart';
import 'schema_index.dart';
import 'schema_docs.dart';

class SchemaContext {
  SchemaContext({required this.schema, required this.index});

  final Schema schema;
  final SchemaIndex index;
}

/// Coordinates the individual codegen stages so they can be exercised
/// independently: schema load, operations load, IR build, and render.
class CodegenPipeline {
  CodegenPipeline({
    required this.config,
    required this.renderer,
    required this.plugins,
    required this.cache,
    OperationsLoader? operationsLoader,
  }) : operationsLoader =
            operationsLoader ?? OperationsLoader(inputDir: config.inputDir);

  final Config config;
  final Renderer renderer;
  final List<GeneratorPlugin> plugins;
  final IrCache cache;
  final OperationsLoader operationsLoader;

  Future<SchemaContext> loadSchema() async {
    final schemaFile = File(config.schemaPath);
    if (!schemaFile.existsSync()) {
      throw StateError('Schema file not found at ${config.schemaPath}');
    }
    final schemaSource = await schemaFile.readAsString();
    final schema = Schema.parse(schemaSource);
    return SchemaContext(schema: schema, index: SchemaIndex(schema));
  }

  Future<OperationsBundle> loadOperations() => operationsLoader.load();

  DocumentSource mergeDocuments(List<DocumentSource> sources) {
    final defs = <DefinitionNode>[];
    for (final src in sources) {
      defs.addAll(src.document.definitions);
    }
    final basePath = config.schemaPath;
    final mergedDoc = DocumentNode(definitions: defs);
    return DocumentSource(path: basePath, document: mergedDoc);
  }

  DocumentIr buildIr(DocumentSource merged, SchemaContext schemaCtx) {
    final context = IrBuildContext(
      config: config,
      schema: schemaCtx.schema,
      schemaIndex: schemaCtx.index,
      cache: cache,
      docs: SchemaDocHelper(schemaCtx.schema),
    );
    return DocumentIrBuilder(context).build(merged);
  }

  Future<void> render(DocumentIr ir) => renderer.render(ir, config, plugins);
}
