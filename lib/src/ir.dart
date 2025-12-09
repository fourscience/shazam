import 'package:gql/ast.dart';

/// In-memory representation of a GraphQL document with operations and fragments.
class DocumentIr {
  DocumentIr({
    required this.path,
    required this.operations,
    required this.fragments,
    required this.records,
    required this.interfaceImplementations,
    required this.unionVariants,
    required this.enums,
  });

  final String path;
  final List<OperationIr> operations;
  final List<FragmentIr> fragments;
  final List<RecordIr> records;
  final Map<String, Set<String>> interfaceImplementations;
  final Map<String, Set<String>> unionVariants;
  final List<EnumIr> enums;
}

class OperationIr {
  OperationIr({
    required this.name,
    required this.type,
    required this.node,
    required this.record,
    required this.fragments,
    this.variableRecord,
    Map<String, dynamic>? variableDefaults,
  }) : variableDefaults = variableDefaults ?? const {};

  final String name;
  final OperationType type;
  final OperationDefinitionNode node;
  final RecordIr record;
  final Set<String> fragments;
  final RecordIr? variableRecord;
  final Map<String, dynamic> variableDefaults;
}

class FragmentIr {
  FragmentIr({
    required this.name,
    required this.node,
    required this.record,
    required this.dependencies,
  });

  final String name;
  final FragmentDefinitionNode node;
  final RecordIr record;
  final Set<String> dependencies;
}

class RecordIr {
  RecordIr(
      {required this.name,
      required this.fields,
      this.owner,
      this.isInput = false,
      this.description,
      Set<String>? variants})
      : variants = variants ?? <String>{};
  final String name;
  final Map<String, FieldIr> fields;
  final String? owner; // fragment or operation that owns this record
  final bool isInput;
  final Set<String> variants;
  final String? description;
}

class FieldIr {
  FieldIr({
    required this.name,
    required this.jsonKey,
    required this.sourceName,
    required this.type,
    required this.nullable,
    this.thunkTarget,
    this.description,
    this.defaultValue,
  });

  final String name;
  final String jsonKey;
  final String sourceName;
  final String type;
  final bool nullable;
  final String?
      thunkTarget; // when type is generated as a thunk, points to real target type
  final String? description;
  final dynamic defaultValue;
}

class EnumIr {
  EnumIr(
      {required this.name,
      required this.values,
      this.description,
      Map<String, String?>? valueDescriptions})
      : valueDescriptions = valueDescriptions ?? const {};
  final String name;
  final List<String> values;
  final String? description;
  final Map<String, String?> valueDescriptions;
}

/// Shared cache for IR reuse across documents.
class IrCache {
  final Map<String, RecordIr> records = {};
  final Map<String, FragmentIr> fragments = {};
}
