import 'package:gql/ast.dart';

import 'package:shazam/src/schema.dart';

/// Centralizes access to descriptions from the parsed schema SDL.
class SchemaDocHelper {
  SchemaDocHelper(this.schema);

  final Schema schema;

  String? typeDescription(String typeName) {
    if (schema.types.containsKey(typeName)) {
      return schema.types[typeName]!.description?.value;
    }
    if (schema.interfaces.containsKey(typeName)) {
      return schema.interfaces[typeName]!.description?.value;
    }
    if (schema.unions.containsKey(typeName)) {
      return schema.unions[typeName]!.description?.value;
    }
    if (schema.inputs.containsKey(typeName)) {
      return schema.inputs[typeName]!.description?.value;
    }
    if (schema.enums.containsKey(typeName)) {
      return schema.enums[typeName]!.description?.value;
    }
    return null;
  }

  String? fieldDescription(String parentType, String fieldName) {
    final typeDef = schema.types[parentType] ?? schema.interfaces[parentType];
    if (typeDef == null) return null;
    final fields = typeDef is ObjectTypeDefinitionNode
        ? typeDef.fields
        : typeDef is InterfaceTypeDefinitionNode
            ? typeDef.fields
            : const <FieldDefinitionNode>[];
    for (final f in fields) {
      if (f.name.value == fieldName) return f.description?.value;
    }
    return null;
  }

  String? inputFieldDescription(String inputName, String fieldName) {
    final input = schema.inputs[inputName];
    if (input == null) return null;
    for (final f in input.fields) {
      if (f.name.value == fieldName) return f.description?.value;
    }
    return null;
  }

  String? enumValueDescription(String enumName, String valueName) {
    final enm = schema.enums[enumName];
    if (enm == null) return null;
    for (final v in enm.values) {
      if (v.name.value == valueName) return v.description?.value;
    }
    return null;
  }
}
