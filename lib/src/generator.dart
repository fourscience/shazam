import 'dart:io';

import 'config.dart';
import 'ir.dart';
import 'log.dart';
import 'pipeline.dart';
import 'plugin.dart';
import 'renderer.dart';
import 'operations.dart';

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
    final pipeline = CodegenPipeline(
      config: config,
      renderer: renderer,
      plugins: plugins,
      cache: cache,
      operationsLoader: OperationsLoader(inputDir: config.inputDir),
    );

    final schemaCtx = await pipeline.loadSchema();
    final operations = await pipeline.loadOperations();

    if (operations.documents.isEmpty) {
      logWarn('No operations found under ${config.inputDir}; nothing to do');
      return;
    }

    final merged = pipeline.mergeDocuments(operations.documents);
    final ir = pipeline.buildIr(merged, schemaCtx);
    await pipeline.render(ir);

    logInfo('Build completed');
  }
}
