import 'package:gql/ast.dart';

import '../ir.dart';
import '../operations.dart';
import '../schema.dart';
import 'fragment_builder.dart';
import 'ir_context.dart';
import 'record_builder.dart';

/// Builds operations IR, stitching in fragments and records.
class OperationBuilder {
  OperationBuilder(this.context, this.recordBuilder, this.fragmentBuilder);

  final IrBuildContext context;
  final RecordBuilder recordBuilder;
  final FragmentBuilder fragmentBuilder;

  final Map<String, OperationIr> operations = {};
  final List<RecordIr> variableRecords = [];

  void build(DocumentSource source) {
    for (final def in source.document.definitions) {
      if (def is OperationDefinitionNode && def.name != null) {
        final opName = def.name!.value;
        final rootType = _rootForOperation(def.type);
        final record = recordBuilder.build(
          rootType: rootType,
          selection: def.selectionSet,
          name: _pref(opName),
          owner: opName,
        );
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
        );
      }
    }
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

  String _pref(String name) => '${context.config.namePrefix}${_pascal(name)}';

  String _pascal(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .map((part) =>
            part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join();
  }

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

    for (final v in def.variableDefinitions) {
      final typeRef = TypeRef.fromNode(v.type);
      final dartType = _dartTypeFor(typeRef);
      record.fields[v.variable.name.value] = FieldIr(
        name: v.variable.name.value,
        jsonKey: v.variable.name.value,
        type: dartType,
        nullable: !typeRef.isNonNull,
      );
    }
    variableRecords.add(record);
    return record;
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
      final target = scalar.target ?? scalar.name!;
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
        return ref.isNonNull ? typeName : '$typeName?';
    }
  }

  String _inputTypeName(String gqlName) {
    final trimmed = gqlName.endsWith('Input')
        ? gqlName.substring(0, gqlName.length - 5)
        : gqlName;
    return '${context.config.namePrefix}${_pascal(trimmed)}Input';
  }
}
