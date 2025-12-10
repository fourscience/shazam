import 'package:code_builder/code_builder.dart';

import 'package:shazam/src/ir/ir.dart';

class EnumEmitter {
  Spec emitEnum(EnumIr enm) {
    return Enum((b) {
      b
        ..name = enm.name
        ..docs.addAll(_docs(enm.description))
        ..values.addAll(enm.values.map((v) => EnumValue((ev) {
              ev
                ..name = _enumCase(v)
                ..docs.addAll(_docs(enm.valueDescriptions[v]));
            })));
    });
  }

  String _enumCase(String name) {
    // ignore: unnecessary_raw_strings, reason: 'Raw regexp keeps escapes minimal.'
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (RegExp(r'^[A-Z0-9_]+$').hasMatch(cleaned)) {
      return cleaned;
    }
    final parts = cleaned.split(RegExp(r'[_\s]+'));
    final camel = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join();
    return camel.isEmpty
        ? 'value'
        : camel[0].toLowerCase() + camel.substring(1);
  }

  List<String> _docs(String? description) =>
      (description == null || description.isEmpty) ? [] : [' $description'];
}
