import 'package:gql/ast.dart';

class RecordBuildInput {
  RecordBuildInput({
    required this.rootType,
    required this.selection,
    required this.name,
    required this.owner,
  });

  final String rootType;
  final SelectionSetNode selection;
  final String name;
  final String owner;
}
