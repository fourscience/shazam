import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/generator_plugin.dart';

class FactoryPlugin extends GeneratorPlugin {
  FactoryPlugin();

  final List<String> calls = [];

  @override
  void onDocument(CodegenContext ctx) {
    calls.add('document:${ctx.ir.path}');
  }

  @override
  void onLibrary(LibraryBuilder library, CodegenContext ctx) {
    calls.add('library:${library.body.length}');
  }

  @override
  void onRenderComplete(CodegenContext ctx) {
    calls.add('complete');
  }
}

List<GeneratorPlugin> shazamPlugins() => <GeneratorPlugin>[FactoryPlugin()];
