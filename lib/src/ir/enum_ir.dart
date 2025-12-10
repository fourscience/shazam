import 'package:shazam/src/ir/intermediate_representation.dart';

class EnumIr implements IntermediateRepresentation {
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
