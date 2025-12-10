import 'package:gql/ast.dart';

import 'package:shazam/src/builders/builder.dart';
import 'package:shazam/src/builders/fragment_builder.dart';
import 'package:shazam/src/builders/ir_build_context.dart';
import 'package:shazam/src/builders/record_build_input.dart';
import 'package:shazam/src/builders/record_builder.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:shazam/src/schema.dart';

/// Builds operations IR, stitching in fragments and records.
class OperationBuilder with Builder<List<OperationIr>, DocumentSource> {
  OperationBuilder(this.context, this.recordBuilder, this.fragmentBuilder)
      : naming = NamingHelper(context.config);

  final IrBuildContext context;
  final RecordBuilder recordBuilder;
  final FragmentBuilder fragmentBuilder;
  final NamingHelper naming;

  final Map<String, OperationIr> operations = {};
  final List<RecordIr> variableRecords = [];
  final Map<String, Map<String, Object?>> variableDefaults = {};

  @override
  List<OperationIr> build(DocumentSource source) {
    operations.clear();
    for (final def in source.document.definitions) {
      if (def is OperationDefinitionNode && def.name != null) {
        final opName = def.name!.value;
        try {
          final rootType = _rootForOperation(def.type);
          final record = recordBuilder.build(RecordBuildInput(
            rootType: rootType,
            selection: def.selectionSet,
            name: _pref(opName),
            owner: opName,
          ));
          final fragDeps = _collectFragments(def.selectionSet);
          // Merge fragment spreads into record fields to ensure reuse.
          for (final fragName in fragDeps) {
            final frag = fragmentBuilder.build(fragName);
            for (final entry in frag.record.fields.entries) {
              recordBuilder.records[record.name]!.fields
                  .putIfAbsent(entry.key, () => entry.value);
            }
          }
          operations[opName] = OperationIr(
            name: opName,
            type: def.type,
            node: def,
            record: record,
            fragments: fragDeps,
            variableRecord: _buildVariables(opName, def),
            variableDefaults:
                variableDefaults[opName] ?? const <String, Object?>{},
          );
        } catch (e, st) {
          Error.throwWithStackTrace(
            StateError(
                'Failed to build operation "$opName": $e. Check schema fields, scalar mappings, and keyword replacements.'),
            st,
          );
        }
      }
    }
    return operations.values.toList();
  }

  String _rootForOperation(OperationType type) {
    switch (type) {
      case OperationType.query:
        return context.schema.queryType ?? 'Query';
      case OperationType.mutation:
        return context.schema.mutationType ?? 'Mutation';
      case OperationType.subscription:
        return context.schema.subscriptionType ?? 'Subscription';
    }
  }

  String _pref(String name) =>
      '${context.config.namePrefix}${naming.pascal(name)}';

  Set<String> _collectFragments(SelectionSetNode set) {
    final result = <String>{};
    for (final sel in set.selections) {
      if (sel is FragmentSpreadNode) {
        result.add(_pref(sel.name.value));
      } else if (sel is InlineFragmentNode) {
        result.addAll(_collectFragments(sel.selectionSet));
      } else if (sel is FieldNode && sel.selectionSet != null) {
        result.addAll(_collectFragments(sel.selectionSet!));
      }
    }
    return result;
  }

  RecordIr? _buildVariables(String opName, OperationDefinitionNode def) {
    if (def.variableDefinitions.isEmpty) return null;
    final name = '${_pref(opName)}Variables';
    final record = RecordIr(
      name: name,
      fields: {},
      owner: opName,
      isInput: true,
    );
    final defaults = <String, dynamic>{};

    for (final v in def.variableDefinitions) {
      final typeRef = TypeRef.fromNode(v.type);
      final dartType = _dartTypeFor(typeRef);
      final fieldName = naming.sanitize(v.variable.name.value);
      record.fields[fieldName] = FieldIr(
        name: fieldName,
        jsonKey: v.variable.name.value,
        sourceName: v.variable.name.value,
        type: dartType,
        nullable: !typeRef.isNonNull,
        thunkTarget: null,
        defaultValue: null,
      );
      final defaultVal = v.defaultValue?.value;
      if (defaultVal != null) {
        defaults[v.variable.name.value] = _valueFromNode(defaultVal);
      }
    }
    variableRecords.add(record);
    variableDefaults[opName] = defaults;
    return record;
  }

  Object? _valueFromNode(ValueNode node) {
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

  String _dartTypeFor(TypeRef ref) {
    if (ref.isNonNull && ref.name == null && ref.ofType != null) {
      final inner = _dartTypeFor(ref.ofType!);
      return inner.endsWith('?') ? inner.substring(0, inner.length - 1) : inner;
    }
    if (ref.isList) {
      final inner = _dartTypeFor(ref.ofType!);
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
        final typeName = _pref(base);
        if (context.schema.scalars.contains(base)) {
          return ref.isNonNull ? 'String' : 'String?';
        }
        return ref.isNonNull ? typeName : '$typeName?';
    }
  }

  String _inputTypeName(String gqlName) {
    final trimmed = gqlName.endsWith('Input')
        ? gqlName.substring(0, gqlName.length - 5)
        : gqlName;
    return '${context.config.namePrefix}${naming.pascal(trimmed)}Input';
  }
}
