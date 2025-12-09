import 'package:code_builder/code_builder.dart';
import 'ir.dart';

/// Extension point for custom behavior in the generation pipeline.
abstract class GeneratorPlugin {
  /// Invoked right after IR is built, before any rendering.
  void onDocument(DocumentIr ir, RenderContext context) {}

  /// Invoked before a library is emitted for a document; plugins may mutate the builder.
  void onLibrary(
      LibraryBuilder library, DocumentIr ir, RenderContext context) {}

  /// Invoked after all files for a document are written.
  void onRenderComplete(DocumentIr ir, RenderContext context) {}
}

/// Context passed to plugins with useful metadata about the render operation.
class RenderContext {
  RenderContext({required this.outputRoot, required this.config});

  /// Directory where outputs are written for the current document.
  final String outputRoot;

  /// The configuration used for generation.
  final dynamic config;
}
