import 'package:collection/collection.dart';
import 'package:gql/ast.dart';
import 'package:shazam/src/builders/builder.dart';
import 'package:shazam/src/builders/ir_build_context.dart';
import 'package:shazam/src/builders/record_build_input.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:shazam/src/schema.dart';

/// Builds record IRs (typedef shapes) with caching and schema-aware lookups.
class RecordBuilder with Builder<RecordIr, RecordBuildInput> {
  RecordBuilder(this.context, {this.resolveFragment})
      : naming = NamingHelper(context.config);

  final IrBuildContext context;
  final RecordIr? Function(String name)? resolveFragment;
  final NamingHelper naming;

  final Map<String, RecordIr> records = {};

  @override
  RecordIr build(RecordBuildInput input) {
    final cacheKey = input.name;
    if (context.cache.records.containsKey(cacheKey)) {
      records[cacheKey] = context.cache.records[cacheKey]!;
      return context.cache.records[cacheKey]!;
    }
    if (records.containsKey(cacheKey)) return records[cacheKey]!;
    final spec = RecordIr(
      name: input.name,
      fields: {},
      owner: input.owner,
      variants: {},
      description: context.docs.typeDescription(input.rootType),
    );
    records[cacheKey] = spec;

    final parentFields = _fieldsFor(input.rootType);

    for (final sel in input.selection.selections) {
      if (sel is FieldNode) {
        final jsonKey = sel.alias?.value ?? sel.name.value;
        final rawName = sel.name.value == '__typename' ? 'typeName' : jsonKey;
        final fieldName = naming.sanitize(rawName);
        final fieldDef = parentFields
            ?.firstWhereOrNull((f) => f.name.value == sel.name.value);
        if (fieldDef == null) {
          // __typename is always a non-null String per spec.
          final field = FieldIr(
            name: fieldName,
            jsonKey: jsonKey,
            sourceName: sel.name.value,
            type: sel.name.value == '__typename' ? 'String' : 'dynamic',
            nullable: sel.name.value != '__typename',
            thunkTarget: null,
          );
          spec.fields[fieldName] = field;
          _maybeAddAlias(sel, field, spec);
          continue;
        }
        final typeRef = TypeRef.fromNode(fieldDef.type);
        if (sel.selectionSet == null) {
          final dartType = _dartTypeFor(typeRef,
              hint: fieldDef.type, selectionRecordName: null);
          final fieldDescription =
              context.docs.fieldDescription(input.rootType, sel.name.value);
          final deprecatedReason =
              context.docs.fieldDeprecatedReason(input.rootType, sel.name.value);
          final field = FieldIr(
            name: fieldName,
            jsonKey: jsonKey,
            sourceName: sel.name.value,
            type: dartType,
            nullable: !typeRef.isNonNull,
            thunkTarget: null,
            description: fieldDescription ?? fieldDef.description?.value,
            defaultValue: null,
            deprecatedReason: deprecatedReason,
          );
          spec.fields[fieldName] = field;
          _maybeAddAlias(sel, field, spec);
        } else {
          final typeName =
              _typeNameForSelection(typeRef, sel.selectionSet!, fieldDef.name);
          final selection = sel.selectionSet!;
          final selectionRecordName = _nestedName(
            typeName,
            selection,
            typeRef.isList,
            owner: input.owner,
          );
          final nested = build(RecordBuildInput(
            rootType: typeName,
            selection: selection,
            name: selectionRecordName,
            owner: input.owner,
          ));
          final deprecatedReason =
              context.docs.fieldDeprecatedReason(input.rootType, sel.name.value);
          spec.fields[fieldName] = FieldIr(
            name: fieldName,
            jsonKey: jsonKey,
            sourceName: sel.name.value,
            type: nested.name,
            nullable: !typeRef.isNonNull,
            thunkTarget: null,
            description: fieldDef.description?.value,
            defaultValue: null,
            deprecatedReason: deprecatedReason,
          );
          _maybeAddAlias(sel, spec.fields[fieldName]!, spec);
        }
      } else if (sel is FragmentSpreadNode) {
        final fragName = _pref(sel.name.value);
        final frag = resolveFragment?.call(fragName);
        if (frag != null) {
          spec.fields.addAll(frag.fields);
          spec.variants.add(input.owner);
        }
      } else if (sel is InlineFragmentNode) {
        final typeCondition = sel.typeCondition?.on.name.value;
        if (typeCondition != null) {
          final nestedName = _nestedName(
            typeCondition,
            sel.selectionSet,
            true,
            owner: input.owner,
          );
          final nested = build(
            RecordBuildInput(
              rootType: typeCondition,
              selection: sel.selectionSet,
              name: nestedName,
              owner: input.owner,
            ),
          );
          for (final entry in nested.fields.entries) {
            final existing = spec.fields[entry.key];
            if (existing == null) {
              spec.fields[entry.key] = entry.value;
            }
          }
        }
      }
    }

    spec.variants.add(input.owner);

    return spec;
  }

  void _maybeAddAlias(SelectionNode sel, FieldIr field, RecordIr spec) {
    if (sel is FieldNode && sel.alias != null && sel.alias!.value.isNotEmpty) {
      spec.fields[sel.alias!.value] = field;
    }
  }

  String _nestedName(String typeName, SelectionSetNode selectionSet, bool isList,
      {String? owner}) {
    final fields = <String>{};
    for (final sel in selectionSet.selections) {
      if (sel is FieldNode) {
        fields.add(sel.name.value);
      } else if (sel is FragmentSpreadNode) {
        fields.add(sel.name.value);
      } else if (sel is InlineFragmentNode && sel.typeCondition != null) {
        fields.add(sel.typeCondition!.on.name.value);
      }
    }
    final suffix = isList ? 'List' : '';
    final key = (fields.toList()..sort()).map(naming.pascal).join();
    final selectionKey = key.isEmpty ? 'Selection' : key;
    return '${context.config.namePrefix}${naming.pascal(typeName)}$suffix$selectionKey';
  }

  String _typeNameForSelection(
      TypeRef ref, SelectionSetNode set, NameNode fieldName) {
    if (ref.name != null) return ref.name!;
    if (ref.ofType != null) {
      return _typeNameForSelection(ref.ofType!, set, fieldName);
    }
    throw StateError('Unable to resolve type name for ${fieldName.value}');
  }

  Iterable<FieldDefinitionNode>? _fieldsFor(String typeName) {
    final typeDef = context.schema.types[typeName] ??
        context.schema.interfaces[typeName] ??
        context.schema.unions[typeName];
    if (typeDef is ObjectTypeDefinitionNode) return typeDef.fields;
    if (typeDef is InterfaceTypeDefinitionNode) return typeDef.fields;
    if (typeDef is UnionTypeDefinitionNode) return const [];
    return null;
  }

  String _pref(String name) =>
      '${context.config.namePrefix}${naming.pascal(name)}';

  String _dartTypeFor(TypeRef ref,
      {TypeNode? hint, String? selectionRecordName}) {
    if (ref.isNonNull && ref.name == null && ref.ofType != null) {
      final inner =
          _dartTypeFor(ref.ofType!, hint: hint, selectionRecordName: selectionRecordName);
      return inner.endsWith('?') ? inner.substring(0, inner.length - 1) : inner;
    }
    if (ref.isList) {
      final inner =
          _dartTypeFor(ref.ofType!, hint: hint, selectionRecordName: selectionRecordName);
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
          final nestedName = _pref(base);
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
}
