import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/generator_plugin.dart';

class SinglePlugin extends GeneratorPlugin {
  SinglePlugin();

  @override
  void onDocument(CodegenContext ctx) {}

  @override
  void onLibrary(LibraryBuilder library, CodegenContext ctx) {}

  @override
  void onRenderComplete(CodegenContext ctx) {}
}

final plugin = SinglePlugin();
