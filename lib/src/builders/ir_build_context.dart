import 'package:shazam/src/config.dart';
import 'package:shazam/src/document_ir.dart';
import 'package:shazam/src/schema.dart';
import 'package:shazam/src/schema_doc_helper.dart';
import 'package:shazam/src/schema_index.dart';

/// Shared context passed to IR builders.
class IrBuildContext {
  IrBuildContext({
    required this.config,
    required this.schema,
    required this.schemaIndex,
    required this.cache,
    required this.docs,
  });

  final Config config;
  final Schema schema;
  final SchemaIndex schemaIndex;
  final IrCache cache;
  final SchemaDocHelper docs;
}
