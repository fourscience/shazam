import 'package:code_builder/code_builder.dart';

import 'package:shazam/src/alias_helper.dart';
import 'package:shazam/src/ir.dart';
import 'package:shazam/src/name_type_helpers.dart';

import 'serializer_emitter.dart';

class RecordEmitter {
  RecordEmitter(this.typeHelper, this.serializer)
      : aliasHelper = const AliasHelper();

  final TypeHelper typeHelper;
  final SerializerEmitter serializer;
  final AliasHelper aliasHelper;

  List<Spec> emitRecord(
      RecordIr record, Set<String> recordNames, Set<String> enumNames) {
    final fields = record.fields.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final hasThunk = record.isInput && fields.any((f) => f.thunkTarget != null);
    if (hasThunk) {
      return _emitRecursiveInput(record, fields, recordNames, enumNames);
    }

    final specs = <Spec>[];
    final typedefBuf = StringBuffer();
    if (record.description != null && record.description!.isNotEmpty) {
      typedefBuf.writeln('/// ${record.description}');
    }
    typedefBuf.writeln('typedef ${record.name} = ({');
    for (final f in fields) {
      if (f.description != null && f.description!.isNotEmpty) {
        typedefBuf.writeln('  /// ${f.description}');
      }
      typedefBuf.writeln('  ${f.type} ${f.name},');
    }
    typedefBuf.writeln('});');
    specs.add(Code(typedefBuf.toString()));

    final deserialize = Method((b) {
      b
        ..name = 'deserialize${record.name}'
        ..returns = refer(record.name)
        ..requiredParameters.add(Parameter((p) => p
          ..name = 'json'
          ..type = refer('Map<String, dynamic>')));
      final bodyBuf = StringBuffer()..writeln('return (');
      for (final f in fields) {
        final expr = serializer.deserializeForType(
            f.type, aliasHelper.jsonAccess(f), recordNames, enumNames,
            thunkTarget: f.thunkTarget);
        bodyBuf.writeln('  ${f.name}: $expr,');
      }
      bodyBuf.writeln(');');
      b.body = Code(bodyBuf.toString());
    });
    specs.add(deserialize);

    if (record.isInput) {
      final serialize = Method((b) {
        b
          ..name = 'serialize${record.name}'
          ..returns = refer('Map<String, dynamic>')
          ..requiredParameters.add(Parameter((p) => p
            ..name = 'data'
            ..type = refer(record.name)));
        final bodyBuf = StringBuffer()..writeln('return {');
        for (final f in fields) {
          final expr = serializer.serializeForType(
              f.type, 'data.${f.name}', recordNames, enumNames,
              thunkTarget: f.thunkTarget);
          if (record.isInput && f.defaultValue != null) {
            bodyBuf.writeln(
                "  if (data.${f.name} != null) '${f.jsonKey}': $expr,");
          } else {
            bodyBuf.writeln("  '${f.jsonKey}': $expr,");
          }
        }
        bodyBuf.writeln('};');
        b.body = Code(bodyBuf.toString());
      });
      specs.add(serialize);
    }

    if (record.variants.isNotEmpty) {
      specs.add(_emitMatcher(record, recordNames));
    }

    return specs;
  }

  Spec _emitMatcher(RecordIr record, Set<String> recordNames) {
    final entries = <Map<String, String>>[];
    for (final field in record.fields.values) {
      final core = typeHelper.coreType(field.type);
      if (recordNames.contains(core) && field.nullable) {
        entries.add({'variant': core, 'field': field.name, 'type': core});
      }
    }
    if (entries.isEmpty) return Code('');

    return Extension((b) {
      b
        ..name = '${record.name}Matcher'
        ..on = refer(record.name);

      b.methods.add(Method((m) {
        m
          ..name = 'when'
          ..types.add(refer('T'))
          ..returns = refer('T')
          ..requiredParameters.add(Parameter((p) => p
            ..name = 'orElse'
            ..type = refer('T Function()')))
          ..optionalParameters.addAll(entries.map((entry) {
            final fieldName = entry['field']!;
            final type = entry['type']!;
            return Parameter((p) => p
              ..name = fieldName
              ..named = true
              ..required = true
              ..type = refer('T Function($type)'));
          }));
        final body = StringBuffer();
        for (final entry in entries) {
          final fieldName = entry['field']!;
          body.writeln(
              'if (this.$fieldName != null) return $fieldName(this.$fieldName!);');
        }
        body.writeln('return orElse();');
        m.body = Code(body.toString());
      }));

      b.methods.add(Method((m) {
        m
          ..name = 'maybeWhen'
          ..types.add(refer('T'))
          ..returns = refer('T?')
          ..optionalParameters.addAll(entries.map((entry) {
            final fieldName = entry['field']!;
            final type = entry['type']!;
            return Parameter((p) => p
              ..name = fieldName
              ..named = true
              ..type = refer('T Function($type)?'));
          }))
          ..optionalParameters.add(Parameter((p) => p
            ..name = 'orElse'
            ..named = true
            ..type = refer('T Function()?')));
        final body = StringBuffer();
        for (final entry in entries) {
          final fieldName = entry['field']!;
          body.writeln(
              'if ($fieldName != null && this.$fieldName != null) { return $fieldName(this.$fieldName!); }');
        }
        body.writeln('return orElse?.call();');
        m.body = Code(body.toString());
      }));
    });
  }

  List<Spec> _emitRecursiveInput(RecordIr record, List<FieldIr> fields,
      Set<String> recordNames, Set<String> enumNames) {
    final specs = <Spec>[];

    final classBuf = StringBuffer();
    if (record.description != null && record.description!.isNotEmpty) {
      classBuf.writeln('/// ${record.description}');
    }
    classBuf
      ..writeln('class ${record.name} {')
      ..writeln('  const ${record.name}({');
    for (final f in fields) {
      classBuf.writeln('    this.${f.name},');
    }
    classBuf.writeln('  });');
    for (final f in fields) {
      if (f.description != null && f.description!.isNotEmpty) {
        classBuf.writeln('  /// ${f.description}');
      }
      classBuf.writeln('  final ${f.type} ${f.name};');
    }
    classBuf.writeln('}');
    specs.add(Code(classBuf.toString()));

    final deserBuf = StringBuffer()
      ..writeln(
          '${record.name} deserialize${record.name}(Map<String, dynamic> json) {')
      ..writeln('  return ${record.name}(');
    for (final f in fields) {
      final expr = serializer.deserializeForType(
          f.type, aliasHelper.jsonAccess(f), recordNames, enumNames,
          thunkTarget: f.thunkTarget);
      deserBuf.writeln('    ${f.name}: $expr,');
    }
    deserBuf.writeln('  );');
    deserBuf.writeln('}');
    specs.add(Code(deserBuf.toString()));

    final serBuf = StringBuffer()
      ..writeln(
          'Map<String, dynamic> serialize${record.name}(${record.name} data) {')
      ..writeln('  final _result = <String, dynamic>{');
    for (final f in fields.where((f) => f.thunkTarget == null)) {
      final expr = serializer.serializeForType(
          f.type, 'data.${f.name}', recordNames, enumNames);
      if (record.isInput && f.defaultValue != null) {
        serBuf
            .writeln("    if (data.${f.name} != null) '${f.jsonKey}': $expr,");
      } else {
        serBuf.writeln("    '${f.jsonKey}': $expr,");
      }
    }
    serBuf.writeln('  };');
    for (final f in fields.where((f) => f.thunkTarget != null)) {
      final temp = '_${f.name}Value';
      serBuf.writeln('  final $temp = data.${f.name}?.call();');
      serBuf.writeln('  if ($temp != null) {');
      final inner = serializer.serializeForType(
          f.thunkTarget!, temp, recordNames, enumNames);
      serBuf.writeln("    _result['${f.jsonKey}'] = $inner;");
      serBuf.writeln('  }');
    }
    serBuf.writeln('  return _result;');
    serBuf.writeln('}');
    specs.add(Code(serBuf.toString()));

    return specs;
  }

}
