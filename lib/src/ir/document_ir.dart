import 'package:shazam/src/ir/enum_ir.dart';
import 'package:shazam/src/ir/fragment_ir.dart';
import 'package:shazam/src/ir/intermediate_representation.dart';
import 'package:shazam/src/ir/operation_ir.dart';
import 'package:shazam/src/ir/record_ir.dart';

/// In-memory representation of a GraphQL document with operations and fragments.
class DocumentIr implements IntermediateRepresentation {
  DocumentIr({
    required this.path,
    required this.operations,
    required this.fragments,
    required this.records,
    required this.interfaceImplementations,
    required this.unionVariants,
    required this.enums,
    required this.operationOrigins,
    required this.fragmentOrigins,
  });

  final String path;
  final List<OperationIr> operations;
  final List<FragmentIr> fragments;
  final List<RecordIr> records;
  final Map<String, Set<String>> interfaceImplementations;
  final Map<String, Set<String>> unionVariants;
  final List<EnumIr> enums;
  final Map<String, String> operationOrigins;
  final Map<String, String> fragmentOrigins;
}
