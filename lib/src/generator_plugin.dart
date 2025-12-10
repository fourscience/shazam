import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/document_ir.dart';

/// Semantic version of the IR surface passed to plugins.
/// Bump when breaking changes are made to [DocumentIr] or related models.
const irSchemaVersion = '1.0.0';

/// Declares what a plugin can do and any optional filters.
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.version,
    this.capabilities = const [
      PluginCapability.document,
      PluginCapability.library,
      PluginCapability.renderComplete,
    ],
    this.operationFilter,
    this.fragmentFilter,
    this.requiresSandbox = false,
  });

  /// Unique identifier for the plugin (e.g., package name).
  final String id;

  /// Plugin implementation version (semantic preferred).
  final String version;

  /// Hooks this plugin implements.
  final List<PluginCapability> capabilities;

  /// If provided, restricts callbacks to operations whose names match.
  final RegExp? operationFilter;

  /// If provided, restricts callbacks to fragments whose names match.
  final RegExp? fragmentFilter;

  /// Indicates the plugin expects to run in an isolate/sandbox.
  final bool requiresSandbox;

  bool allowsOperation(String name) =>
      operationFilter == null || operationFilter!.hasMatch(name);

  bool allowsFragment(String name) =>
      fragmentFilter == null || fragmentFilter!.hasMatch(name);
}

enum PluginCapability { document, library, renderComplete }

class PluginServices {
  const PluginServices({required this.logInfo, required this.logWarn});

  final void Function(String message) logInfo;
  final void Function(String message) logWarn;
}

class PluginRegistration {
  const PluginRegistration({required this.plugin, required this.manifest});

  final GeneratorPlugin plugin;
  final PluginManifest manifest;
}

/// Extension point for custom behavior in the generation pipeline.
/// Plugins may:
/// - read IR to make decisions
/// - add/modify imports and declarations on emitted libraries via [onLibrary]
/// - emit extra files by writing to [RenderContext.outputRoot] in hooks
/// Plugins must NOT mutate IR contents (e.g., add/remove fields) to ensure
/// stability for other plugins.
abstract class GeneratorPlugin {
  /// Invoked right after IR is built, before any rendering.
  /// Safe for analytics or preparing additional artifacts; avoid mutating IR.
  void onDocument(CodegenContext ctx);

  /// Invoked before a library is emitted for a document; plugins may mutate the builder.
  /// Allowed: add imports, add declarations, annotate code, register parts.
  /// Avoid removing user-generated code or changing existing declarations.
  void onLibrary(LibraryBuilder library, CodegenContext ctx);

  /// Invoked after all files for a document are written.
  /// Use this to emit extra files into [CodegenContext.outputRoot] or
  /// perform cleanup. Do not assume synchronous ordering between documents.
  void onRenderComplete(CodegenContext ctx);
}

/// Context passed to plugins with useful metadata about the render operation.
class RenderContext {
  const RenderContext({required this.outputRoot, required this.config});

  /// Directory where outputs are written for the current document.
  final String outputRoot;

  /// The configuration used for generation.
  final Object config;
}

/// Aggregated context passed to plugins for convenience.
class CodegenContext {
  CodegenContext({
    required this.ir,
    required this.render,
    required this.config,
    this.services = const PluginServices(
      logInfo: _defaultLogInfo,
      logWarn: _defaultLogWarn,
    ),
  });

  final DocumentIr ir;
  final RenderContext render;
  final Object config;
  final PluginServices services;
}

void _defaultLogInfo(String msg) {}

void _defaultLogWarn(String msg) {}

/// Example plugin that injects a comment into every generated library:
///
/// class BannerPlugin implements GeneratorPlugin {
///   @override
///   void onLibrary(LibraryBuilder library, DocumentIr ir, RenderContext ctx) {
///     library.body.insert(0, Code('// Generated with love by BannerPlugin'));
///   }
/// }
