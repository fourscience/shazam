import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/generator_plugin.dart';

class ListPlugin extends GeneratorPlugin {
  ListPlugin();

  @override
  void onDocument(CodegenContext ctx) {}

  @override
  void onLibrary(LibraryBuilder library, CodegenContext ctx) {}

  @override
  void onRenderComplete(CodegenContext ctx) {}
}

final plugins = <GeneratorPlugin>[ListPlugin(), ListPlugin()];
