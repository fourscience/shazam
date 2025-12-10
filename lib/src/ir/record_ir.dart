import 'package:shazam/src/ir/field_ir.dart';
import 'package:shazam/src/ir/intermediate_representation.dart';

class RecordIr implements IntermediateRepresentation {
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
