import 'package:code_builder/code_builder.dart';

import 'package:shazam/src/emitters/emitter.dart';
import 'package:shazam/src/ir/ir.dart';

class EnumEmitter implements Emitter<Spec> {
  @override
  Spec emit() {
    throw UnimplementedError('Use emitEnum to provide EnumIr');
  }

  Spec emitEnum(EnumIr enm) {
    return Enum((b) {
      b
        ..name = enm.name
        ..docs.addAll(_docs(enm.description))
        ..values.addAll(enm.values.map((v) => EnumValue((ev) {
              ev
                ..name = _enumCase(v)
                ..annotations.addAll(_deprecated(enm.valueDeprecations[v]))
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

  Iterable<Expression> _deprecated(String? reason) {
    if (reason == null) return const [];
    return [refer('Deprecated').call([literalString(reason)])];
  }
}
