import 'package:gql/ast.dart';
import 'package:shazam/src/ir/intermediate_representation.dart';
import 'package:shazam/src/ir/record_ir.dart';

class OperationIr implements IntermediateRepresentation {
  OperationIr({
    required this.name,
    required this.type,
    required this.node,
    required this.record,
    required this.fragments,
    this.variableRecord,
    Map<String, Object?>? variableDefaults,
  }) : variableDefaults =
            variableDefaults ?? const <String, Object?>{};

  final String name;
  final OperationType type;
  final OperationDefinitionNode node;
  final RecordIr record;
  final Set<String> fragments;
  final RecordIr? variableRecord;
  final Map<String, Object?> variableDefaults;
}
