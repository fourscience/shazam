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
  });

  final String name;
  final OperationType type;
  final OperationDefinitionNode node;
  final RecordIr record;
  final Set<String> fragments;
  final RecordIr? variableRecord;
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
      Set<String>? variants})
      : variants = variants ?? <String>{};
  final String name;
  final Map<String, FieldIr> fields;
  final String? owner; // fragment or operation that owns this record
  final bool isInput;
  final Set<String> variants;
}

class FieldIr {
  FieldIr({
    required this.name,
    required this.jsonKey,
    required this.type,
    required this.nullable,
    this.thunkTarget,
  });

  final String name;
  final String jsonKey;
  final String type;
  final bool nullable;
  final String?
      thunkTarget; // when type is generated as a thunk, points to real target type
}

class EnumIr {
  EnumIr({required this.name, required this.values});
  final String name;
  final List<String> values;
}

/// Shared cache for IR reuse across documents.
class IrCache {
  final Map<String, RecordIr> records = {};
  final Map<String, FragmentIr> fragments = {};
}
