import 'package:shazam/src/ir/fragment_ir.dart';
import 'package:shazam/src/ir/intermediate_representation.dart';
import 'package:shazam/src/ir/record_ir.dart';

/// Shared cache for IR reuse across documents.
class IrCache implements IntermediateRepresentation {
  final Map<String, RecordIr> records = {};
  final Map<String, FragmentIr> fragments = {};
}
