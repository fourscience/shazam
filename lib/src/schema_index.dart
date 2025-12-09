import 'package:gql/ast.dart';

import 'package:shazam/src/schema.dart';

/// Read-only index over parsed schema definitions to centralize lookups.
class SchemaIndex {
  SchemaIndex(this.schema) {
    _interfaceImpls = _computeInterfaceImpls();
    _unionVariants = _computeUnionVariants();
  }

  final Schema schema;
  late final Map<String, Set<String>> _interfaceImpls;
  late final Map<String, Set<String>> _unionVariants;

  /// Return the field definitions for a concrete type or interface, if known.
  List<FieldDefinitionNode>? fieldsFor(String typeName) {
    if (schema.types.containsKey(typeName)) {
      return schema.types[typeName]!.fields;
    }
    if (schema.interfaces.containsKey(typeName)) {
      return schema.interfaces[typeName]!.fields;
    }
    return null;
  }

  /// Whether the given type is a union or interface.
  bool isUnionOrInterface(String typeName) {
    return schema.unions.containsKey(typeName) ||
        schema.interfaces.containsKey(typeName);
  }

  Map<String, Set<String>> interfaceImplementations() => _interfaceImpls;
  Map<String, Set<String>> unionVariants() => _unionVariants;

  Map<String, Set<String>> _computeInterfaceImpls() {
    final map = <String, Set<String>>{};
    for (final entry in schema.types.entries) {
      for (final iface in entry.value.interfaces) {
        map.putIfAbsent(iface.name.value, () => <String>{}).add(entry.key);
      }
    }
    return map;
  }

  Map<String, Set<String>> _computeUnionVariants() {
    final map = <String, Set<String>>{};
    for (final entry in schema.unions.entries) {
      final members = entry.value.types.map((t) => t.name.value).toSet();
      map[entry.key] = members;
    }
    return map;
  }
}
