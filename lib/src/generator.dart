import 'package:shazam/src/codegen_pipeline.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/document_ir.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/log.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:shazam/src/plugin_loader.dart';
import 'package:shazam/src/renderer.dart';

typedef RendererFactory = Renderer Function(Config config);
typedef OperationsLoaderFactory = OperationsLoader Function(String inputDir);
typedef CacheFactory = IrCache Function();

/// Top-level coordinator that parses GraphQL sources, builds IR, and renders code.
class Generator {
  /// [renderer], [operationsLoader], and [cache] can be injected for testing or
  /// customization. When omitted, they are created via the corresponding
  /// factory parameters, which default to the built-in implementations.
  Generator(
    this.config, {
    List<GeneratorPlugin>? plugins,
    Renderer? renderer,
    IrCache? cache,
    OperationsLoader? operationsLoader,
    RendererFactory rendererFactory = _defaultRendererFactory,
    OperationsLoaderFactory operationsLoaderFactory =
        _defaultOperationsLoaderFactory,
    CacheFactory cacheFactory = _defaultCacheFactory,
    this.pluginLoader = const PluginLoader(),
  })  : plugins = plugins ?? [],
        renderer = renderer ?? rendererFactory(config),
        cache = cache ?? cacheFactory(),
        operationsLoader =
            operationsLoader ?? operationsLoaderFactory(config.inputDir);

  final Config config;
  final List<GeneratorPlugin> plugins;
  final Renderer renderer;
  final IrCache cache;
  final OperationsLoader operationsLoader;
  final PluginLoader pluginLoader;

  Future<void> build() async {
    final activePlugins =
        plugins.isNotEmpty ? plugins : await pluginLoader.load(config);
    final pipeline = CodegenPipeline(
      config: config,
      renderer: renderer,
      plugins: activePlugins,
      cache: cache,
      operationsLoader: operationsLoader,
    );

    try {
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
    } catch (e) {
      logError(
          'Generation failed: $e\nHints: verify schema path "${config.schemaPath}", custom scalar mappings, and keyword replacements. If the failure mentions an operation/fragment, check its selections against the schema.');
      rethrow;
    }
  }

  static Renderer _defaultRendererFactory(Config config) =>
      CodeRenderer(config);
  static OperationsLoader _defaultOperationsLoaderFactory(String inputDir) =>
      OperationsLoader(inputDir: inputDir);
  static IrCache _defaultCacheFactory() => IrCache();
}
