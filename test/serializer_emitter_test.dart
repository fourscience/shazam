import 'package:test/test.dart';

import 'package:shazam/src/config.dart';
import 'package:shazam/src/emitters/serializer_emitter.dart';
import 'package:shazam/src/name_type_helpers.dart';

void main() {
  group('SerializerEmitter', () {
    const helper = TypeHelper();
    final emitter = SerializerEmitter(helper, {
      'CustomDateTime': const ScalarConfig(
        symbol: 'CustomDateTime',
        import: 'package:custom/scalars.dart',
      )
    });

    test('deserializes nullable list of custom scalars with serializer', () {
      final code = emitter.deserializeForType(
        'List<CustomDateTime?>?',
        "json['events']",
        {},
        {},
      );
      expect(code,
          "(json['events'] as List?)?.map((e) => e == null ? null : CustomDateTime.deserialize(e as String)).toList()");
    });

    test('deserializes primitive scalar without calling serializer', () {
      final emitterNoImport =
          SerializerEmitter(helper, {'Age': const ScalarConfig(symbol: 'int')});
      final code = emitterNoImport.deserializeForType(
          'Age?', "json['age']", {}, {});
      expect(code, "json['age'] as int?");
    });
  });
}
