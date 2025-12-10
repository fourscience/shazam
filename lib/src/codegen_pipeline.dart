import 'dart:io';

import 'package:shazam/src/builders/document_ir_builder.dart';
import 'package:shazam/src/builders/ir_build_context.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:shazam/src/renderer.dart';
import 'package:shazam/src/schema.dart';
import 'package:shazam/src/schema_doc_helper.dart';
import 'package:shazam/src/schema_index.dart';

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
  final List<PluginRegistration> plugins;
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

  List<DocumentIr> buildAll(
      List<DocumentSource> sources, SchemaContext schemaCtx) {
    final context = IrBuildContext(
      config: config,
      schema: schemaCtx.schema,
      schemaIndex: schemaCtx.index,
      cache: cache,
      docs: SchemaDocHelper(schemaCtx.schema),
    );
    final builder = DocumentIrBuilder(context);
    return [
      for (final src in sources) builder.build(src, allSources: sources),
    ];
  }

  Future<void> render(DocumentIr ir) => renderer.render(ir, config, plugins);

  Future<void> renderShared(DocumentIr merged) =>
      renderer.renderShared(merged, config, plugins);
}

class SchemaContext {
  SchemaContext({required this.schema, required this.index});

  final Schema schema;
  final SchemaIndex index;
}
