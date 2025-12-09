import 'package:shazam/src/ir.dart';

/// Centralized helper for handling aliased field JSON access.
class AliasHelper {
  const AliasHelper();

  /// Returns the JSON expression to read a field, falling back to the source
  /// name when an alias was used.
  String jsonAccess(FieldIr field) {
    if (field.jsonKey == field.sourceName) {
      return "json['${field.jsonKey}']";
    }
    return "json['${field.jsonKey}'] ?? json['${field.sourceName}']";
  }
}
