import 'package:shazam/src/ir/intermediate_representation.dart';

class FieldIr implements IntermediateRepresentation {
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
  final Object? defaultValue;
}
