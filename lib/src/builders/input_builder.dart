import 'package:gql/ast.dart';

import '../ir.dart';
import '../schema.dart';
import 'ir_context.dart';

/// Builds IR records for input objects, suffixing names with `Input`.
class InputBuilder {
  InputBuilder(this.context);

  final IrBuildContext context;

  /// Build all input object records from the schema.
  List<RecordIr> buildAll() {
    final records = <RecordIr>[];
    for (final entry in context.schema.inputs.entries) {
      records.add(_buildForInput(entry.value));
    }
    return records;
  }

  RecordIr _buildForInput(InputObjectTypeDefinitionNode input) {
    final name = _inputTypeName(input.name.value);
    if (context.cache.records.containsKey(name)) {
      return context.cache.records[name]!;
    }
    final record =
        RecordIr(name: name, fields: {}, isInput: true, variants: {});
    context.cache.records[name] = record;

    for (final field in input.fields) {
      final typeRef = TypeRef.fromNode(field.type);
      final dartType = _dartTypeFor(typeRef, selectionRecordName: null);
      record.fields[field.name.value] = FieldIr(
        name: _sanitize(field.name.value),
        jsonKey: field.name.value,
        type: dartType,
        nullable: !typeRef.isNonNull,
        thunkTarget: null,
      );
    }
    return record;
  }

  String _dartTypeFor(TypeRef ref, {String? selectionRecordName}) {
    if (ref.isNonNull && ref.name == null && ref.ofType != null) {
      final inner =
          _dartTypeFor(ref.ofType!, selectionRecordName: selectionRecordName);
      return inner.endsWith('?') ? inner.substring(0, inner.length - 1) : inner;
    }
    if (ref.isList) {
      final inner =
          _dartTypeFor(ref.ofType!, selectionRecordName: selectionRecordName);
      final listType = 'List<$inner>';
      return ref.isNonNull ? listType : '$listType?';
    }
    final base = ref.name!;
    final scalar = context.config.scalarMapping[base];
    if (scalar != null) {
      final target = scalar.symbol;
      return ref.isNonNull ? target : '$target?';
    }
    switch (base) {
      case 'ID':
      case 'String':
        return ref.isNonNull ? 'String' : 'String?';
      case 'Int':
        return ref.isNonNull ? 'int' : 'int?';
      case 'Float':
        return ref.isNonNull ? 'double' : 'double?';
      case 'Boolean':
        return ref.isNonNull ? 'bool' : 'bool?';
      default:
        if (context.schema.enums.containsKey(base)) {
          final enumName = _pref(base);
          return ref.isNonNull ? enumName : '$enumName?';
        }
        if (context.schema.inputs.containsKey(base)) {
          final nestedName = _inputTypeName(base);
          return ref.isNonNull ? nestedName : '$nestedName?';
        }
        return ref.isNonNull
            ? selectionRecordName ?? base
            : '${selectionRecordName ?? base}?';
    }
  }

  String _inputTypeName(String gqlName) {
    final trimmed = gqlName.endsWith('Input')
        ? gqlName.substring(0, gqlName.length - 5)
        : gqlName;
    return '${context.config.namePrefix}${_pascal(trimmed)}Input';
  }

  String _pref(String name) => '${context.config.namePrefix}${_pascal(name)}';

  String _pascal(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .map((part) =>
            part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join();
  }

  String _sanitize(String name) => context.config.sanitizeIdentifier(name);
}
