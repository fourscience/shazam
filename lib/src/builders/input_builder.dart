import 'package:gql/ast.dart';

import 'package:shazam/src/builders/builder.dart';
import 'package:shazam/src/builders/ir_build_context.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:shazam/src/schema.dart';

/// Builds IR records for input objects, suffixing names with `Input`.
class InputBuilder with Builder<RecordIr, InputObjectTypeDefinitionNode> {
  InputBuilder(this.context) : naming = NamingHelper(context.config);

  final IrBuildContext context;
  final NamingHelper naming;

  /// Build all input object records from the schema.
  List<RecordIr> buildAll() => collect(context.schema.inputs.values);

  @override
  RecordIr build(InputObjectTypeDefinitionNode input) {
    final name = _inputTypeName(input.name.value);
    if (context.cache.records.containsKey(name)) {
      return context.cache.records[name]!;
    }
    final record = RecordIr(
      name: name,
      fields: {},
      isInput: true,
      variants: {},
      description: context.docs.typeDescription(input.name.value),
    );
    context.cache.records[name] = record;

    for (final field in input.fields) {
      final typeRef = TypeRef.fromNode(field.type);
      final dartType = _dartTypeFor(typeRef, selectionRecordName: null);
      record.fields[field.name.value] = FieldIr(
        name: naming.sanitize(field.name.value),
        jsonKey: field.name.value,
        sourceName: field.name.value,
        type: dartType,
        nullable: !typeRef.isNonNull,
        thunkTarget: null,
        description:
            context.docs.inputFieldDescription(input.name.value, field.name.value),
        defaultValue: _valueFromNode(field.defaultValue),
        deprecatedReason: context
            .docs
            .inputFieldDeprecatedReason(input.name.value, field.name.value),
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
        if (context.schema.scalars.contains(base)) {
          return ref.isNonNull ? 'String' : 'String?';
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
    return '${context.config.namePrefix}${naming.pascal(trimmed)}Input';
  }

  String _pref(String name) =>
      '${context.config.namePrefix}${naming.pascal(name)}';
  Object? _valueFromNode(ValueNode? node) {
    if (node == null) return null;
    if (node is IntValueNode) return int.parse(node.value);
    if (node is FloatValueNode) return double.parse(node.value);
    if (node is StringValueNode) return node.value;
    if (node is BooleanValueNode) return node.value;
    if (node is EnumValueNode) return node.name.value;
    if (node is ListValueNode) {
      return node.values.map(_valueFromNode).toList();
    }
    if (node is ObjectValueNode) {
      return {
        for (final field in node.fields)
          field.name.value: _valueFromNode(field.value)
      };
    }
    if (node is NullValueNode) return null;
    return null;
  }
}
