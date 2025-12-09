import '../config.dart';
import '../ir.dart';
import '../schema.dart';
import '../schema_index.dart';

/// Shared context passed to IR builders.
class IrBuildContext {
  IrBuildContext({
    required this.config,
    required this.schema,
    required this.schemaIndex,
    required this.cache,
  });

  final Config config;
  final Schema schema;
  final SchemaIndex schemaIndex;
  final IrCache cache;
}
