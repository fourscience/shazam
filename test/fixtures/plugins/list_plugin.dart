import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/generator_plugin.dart';

class ListPlugin extends GeneratorPlugin {
  ListPlugin();

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

final plugins = <GeneratorPlugin>[ListPlugin(), ListPlugin()];
