import 'package:shazam/src/config.dart';
import 'package:shazam/src/document_ir.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:shazam/src/renderer.dart';

class FakeOperationsLoader implements OperationsLoader {
  FakeOperationsLoader(this.bundle);

  final OperationsBundle bundle;
  bool called = false;

  @override
  String get inputDir => '';

  @override
  Future<OperationsBundle> load() async {
    called = true;
    return bundle;
  }
}

class FakeRenderer implements Renderer {
  bool rendered = false;

  @override
  Future<void> render(
    DocumentIr ir,
    Config config,
    List<GeneratorPlugin> plugins,
  ) async {
    rendered = true;
  }
}
