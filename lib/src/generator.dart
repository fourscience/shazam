import 'package:shazam/src/codegen_pipeline.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/ir/ir.dart';
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
    List<PluginRegistration>? plugins,
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
  final List<PluginRegistration> plugins;
  final Renderer renderer;
  final IrCache cache;
  final OperationsLoader operationsLoader;
  final PluginLoader pluginLoader;

  Future<void> build() async {
    configureLogging(config.logLevel);
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

      final irs = pipeline.buildAll(operations.documents, schemaCtx);
      for (final ir in irs) {
        await pipeline.render(ir);
      }
      final merged = _mergeIrs(irs);
      await pipeline.renderShared(merged);

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

  DocumentIr _mergeIrs(List<DocumentIr> irs) {
    final opOrigins = <String, String>{};
    final fragOrigins = <String, String>{};
    final operations = <OperationIr>[];
    final fragments = <FragmentIr>[];
    final records = <String, RecordIr>{};
    final enums = <String, EnumIr>{};
    final interfaceImpls = <String, Set<String>>{};
    final unionVariants = <String, Set<String>>{};

    void mergeSet(Map<String, Set<String>> target, Map<String, Set<String>> src) {
      for (final entry in src.entries) {
        target.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
      }
    }

    for (final ir in irs) {
      operations.addAll(ir.operations);
      fragments.addAll(ir.fragments);
      opOrigins.addAll(ir.operationOrigins);
      fragOrigins.addAll(ir.fragmentOrigins);
      for (final record in ir.records) {
        records.putIfAbsent(record.name, () => record);
      }
      for (final enm in ir.enums) {
        enums.putIfAbsent(enm.name, () => enm);
      }
      mergeSet(interfaceImpls, ir.interfaceImplementations);
      mergeSet(unionVariants, ir.unionVariants);
    }

    return DocumentIr(
      path: config.schemaPath,
      operations: operations,
      fragments: fragments,
      records: records.values.toList(),
      interfaceImplementations: interfaceImpls,
      unionVariants: unionVariants,
      enums: enums.values.toList(),
      operationOrigins: opOrigins,
      fragmentOrigins: fragOrigins,
    );
  }
}
