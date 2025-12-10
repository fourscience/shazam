import 'package:gql/ast.dart';
import 'package:shazam/src/ir/intermediate_representation.dart';
import 'package:shazam/src/ir/record_ir.dart';

class FragmentIr implements IntermediateRepresentation {
  FragmentIr({
    required this.name,
    required this.node,
    required this.record,
    required this.dependencies,
    required this.originPath,
  });

  final String name;
  final FragmentDefinitionNode node;
  final RecordIr record;
  final Set<String> dependencies;
  final String originPath;
}
