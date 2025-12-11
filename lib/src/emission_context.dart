import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';

/// Shared context for emitters with path and import resolution helpers.
class EmissionContext {
  EmissionContext({
    required this.config,
    required this.fragmentOrigins,
    required this.operationOrigins,
  }) : scalarBySymbol = _scalarSymbolMap(config);

  final Config config;
  final Map<String, String> fragmentOrigins;
  final Map<String, String> operationOrigins;
  final Map<String, ScalarConfig> scalarBySymbol;

  String get schemaLibraryPath =>
      p.normalize(p.join(p.dirname(config.schemaPath), 'schema.dart'));

  String get helpersPath => p.join(p.dirname(schemaLibraryPath), 'graphql.g.dart');

  String outputRootFor(String sourcePath) =>
      p.join(p.dirname(sourcePath), config.outputDir);

  String relativeSchemaImport(String fromFile) =>
      p.relative(schemaLibraryPath, from: p.dirname(fromFile));

  String fragmentImportPath(String name, String fromFile) {
    final origin = fragmentOrigins[name];
    if (origin == null || origin.isEmpty) {
      return '../fragments/$name.dart';
    }
    final targetRoot = outputRootFor(origin);
    final target = p.join(targetRoot, 'fragments', '$name.dart');
    return p.relative(target, from: p.dirname(fromFile));
  }

  String operationImportPath(String opName) {
    final origin = operationOrigins[opName];
    if (origin == null) return '$opName.dart';
    final opPath = p.join(outputRootFor(origin), '$opName.dart');
    return p.relative(opPath, from: p.dirname(helpersPath));
  }

  static Map<String, ScalarConfig> _scalarSymbolMap(Config config) {
    final result = <String, ScalarConfig>{};
    for (final entry in config.scalarMapping.entries) {
      result[entry.value.symbol] = entry.value;
    }
    return result;
  }
}
