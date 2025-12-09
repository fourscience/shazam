import 'package:collection/collection.dart';
import 'package:gql/ast.dart';

import '../ir.dart';
import '../name_type_helpers.dart';
import '../schema.dart';
import 'ir_context.dart';

/// Builds record IRs (typedef shapes) with caching and schema-aware lookups.
class RecordBuilder {
  RecordBuilder(this.context, {this.resolveFragment})
      : naming = NamingHelper(context.config);

  final IrBuildContext context;
  final RecordIr? Function(String name)? resolveFragment;
  final NamingHelper naming;

  final Map<String, RecordIr> records = {};

  RecordIr build({
    required String rootType,
    required SelectionSetNode selection,
    required String name,
    String? owner,
  }) {
    if (context.cache.records.containsKey(name)) {
      records[name] = context.cache.records[name]!;
      return context.cache.records[name]!;
    }
    if (records.containsKey(name)) return records[name]!;
    final spec = RecordIr(name: name, fields: {}, owner: owner, variants: {});
    records[name] = spec;

    final parentFields = _fieldsFor(rootType);

    for (final sel in selection.selections) {
      if (sel is FieldNode) {
        final jsonKey = sel.alias?.value ?? sel.name.value;
        final rawName = sel.name.value == '__typename' ? 'typeName' : jsonKey;
        final fieldName = naming.sanitize(rawName);
        final fieldDef = parentFields
            ?.firstWhereOrNull((f) => f.name.value == sel.name.value);
        if (fieldDef == null) {
          spec.fields[fieldName] = FieldIr(
            name: fieldName,
            jsonKey: jsonKey,
            type: 'dynamic',
            nullable: true,
            thunkTarget: null,
          );
          continue;
        }
        final typeRef = TypeRef.fromNode(fieldDef.type);
        if (sel.selectionSet == null) {
          final dartType = _dartTypeFor(typeRef,
              hint: fieldDef.type, selectionRecordName: null);
          spec.fields[fieldName] = FieldIr(
            name: fieldName,
            jsonKey: jsonKey,
            type: dartType,
            nullable: !typeRef.isNonNull,
            thunkTarget: null,
          );
        } else {
          final nestedName = '${name}${naming.pascal(fieldName)}';
          final namedType = _namedType(typeRef);
          final nestedRecord = build(
            rootType: namedType,
            selection: sel.selectionSet!,
            name: nestedName,
            owner: owner,
          );
          final dartType = _wrapType(nestedRecord.name, typeRef);
          spec.fields[fieldName] = FieldIr(
            name: fieldName,
            jsonKey: jsonKey,
            type: dartType,
            nullable: !typeRef.isNonNull,
            thunkTarget: null,
          );
        }
      } else if (sel is FragmentSpreadNode) {
        final fragName = _pref(sel.name.value);
        final fragRecord = resolveFragment?.call(fragName);
        if (fragRecord != null) {
          for (final entry in fragRecord.fields.entries) {
            spec.fields.putIfAbsent(entry.key, () => entry.value);
          }
        }
      } else if (sel is InlineFragmentNode) {
        final typeCondition = sel.typeCondition?.on.name.value;
        if (typeCondition == null) {
          final nested = build(
              rootType: rootType, selection: sel.selectionSet, name: name);
          for (final entry in nested.fields.entries) {
            spec.fields.putIfAbsent(entry.key, () => entry.value);
          }
        } else if (_isUnionOrInterface(rootType)) {
          final variantName = '${name}${naming.pascal(typeCondition)}';
          final nested = build(
              rootType: typeCondition,
              selection: sel.selectionSet,
              name: variantName,
              owner: owner);
          spec.variants.add(typeCondition);
          final variantField = naming.sanitize(naming.camel(typeCondition));
          spec.fields[variantField] = FieldIr(
            name: variantField,
            jsonKey: naming.camel(typeCondition),
            type: '${nested.name}?',
            nullable: true,
            thunkTarget: null,
          );
        }
      }
    }

    final hasTypename =
        spec.fields.values.any((f) => f.jsonKey == '__typename');
    if (!hasTypename) {
      spec.fields['typeName'] = FieldIr(
        name: 'typeName',
        jsonKey: '__typename',
        type: 'String',
        nullable: false,
        thunkTarget: null,
      );
    }

    context.cache.records[name] = spec;
    return spec;
  }

  String _namedType(TypeRef ref) {
    if (ref.name != null) return ref.name!;
    if (ref.ofType != null) return _namedType(ref.ofType!);
    return 'Unknown';
  }

  String _dartTypeFor(TypeRef ref,
      {TypeNode? hint, String? selectionRecordName}) {
    if (ref.isNonNull && ref.name == null && ref.ofType != null) {
      final inner = _dartTypeFor(ref.ofType!,
          hint: hint, selectionRecordName: selectionRecordName);
      return inner.endsWith('?') ? inner.substring(0, inner.length - 1) : inner;
    }
    if (ref.isList) {
      final inner = _dartTypeFor(ref.ofType!,
          hint: hint, selectionRecordName: selectionRecordName);
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
        final typeName = selectionRecordName ?? _pref(base);
        return ref.isNonNull ? typeName : '$typeName?';
    }
  }

  String _wrapType(String name, TypeRef ref) {
    if (ref.isNonNull && ref.name == null && ref.ofType != null) {
      final inner = _wrapType(name, ref.ofType!);
      return inner.endsWith('?') ? inner.substring(0, inner.length - 1) : inner;
    }
    if (ref.isList) {
      final inner = _wrapType(name, ref.ofType!);
      final listType = 'List<$inner>';
      return ref.isNonNull ? listType : '$listType?';
    }
    return ref.isNonNull ? name : '$name?';
  }

  String _pref(String name) =>
      '${context.config.namePrefix}${naming.pascal(name)}';

  bool _isUnionOrInterface(String typeName) =>
      context.schemaIndex.isUnionOrInterface(typeName);

  List<FieldDefinitionNode>? _fieldsFor(String typeName) =>
      context.schemaIndex.fieldsFor(typeName);
}
