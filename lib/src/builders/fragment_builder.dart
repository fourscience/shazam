import 'package:gql/ast.dart';
import 'package:shazam/src/builders/builder.dart';
import 'package:shazam/src/builders/ir_build_context.dart';
import 'package:shazam/src/builders/record_build_input.dart';
import 'package:shazam/src/builders/record_builder.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:shazam/src/operations_loader.dart';

/// Builds fragments and caches them for reuse.
class FragmentBuilder with Builder<FragmentIr, String> {
  FragmentBuilder(this.context, this.recordBuilder)
      : naming = NamingHelper(context.config);

  final IrBuildContext context;
  final RecordBuilder recordBuilder;
  final NamingHelper naming;

  final Map<String, FragmentIr> fragments = {};
  final Map<String, FragmentDefinitionNode> fragmentDefinitions = {};
  final Map<String, String> definitionOrigins = {};

  void indexDefinitions(DocumentSource source) {
    for (final def in source.document.definitions) {
      if (def is FragmentDefinitionNode) {
        final name = _pref(def.name.value);
        fragmentDefinitions[name] = def;
        definitionOrigins.putIfAbsent(name, () => source.path);
      }
    }
  }

  @override
  FragmentIr build(String name) {
    if (fragments.containsKey(name)) return fragments[name]!;
    if (context.cache.fragments.containsKey(name)) {
      fragments[name] = context.cache.fragments[name]!;
      return fragments[name]!;
    }
    final def = fragmentDefinitions[name];
    if (def == null) {
      throw StateError('Fragment $name not found');
    }
    final deps = _collectDeps(def.selectionSet);
    late final RecordIr record;
    try {
      record = recordBuilder.build(RecordBuildInput(
        rootType: def.typeCondition.on.name.value,
        selection: def.selectionSet,
        name: name,
        owner: name,
      ));
    } catch (e, st) {
      Error.throwWithStackTrace(
        StateError(
            'Failed to build fragment "$name": $e. Verify schema fields, scalar mappings, and keyword replacements.'),
        st,
      );
    }
    for (final dep in deps) {
      final depFrag = build(dep);
      for (final entry in depFrag.record.fields.entries) {
        record.fields.putIfAbsent(entry.key, () => entry.value);
      }
    }
    // Explicitly stitch in fields from fragment spreads within this fragment.
    for (final sel in def.selectionSet.selections) {
      if (sel is FragmentSpreadNode) {
        final spread = build(_pref(sel.name.value));
        for (final entry in spread.record.fields.entries) {
          record.fields.putIfAbsent(entry.key, () => entry.value);
        }
      }
    }
    final frag = FragmentIr(
      name: name,
      node: def,
      record: record,
      dependencies: deps,
      originPath: definitionOrigins[name] ?? '',
    );
    fragments[name] = frag;
    context.cache.fragments[name] = frag;
    return frag;
  }

  String _pref(String name) =>
      '${context.config.namePrefix}${naming.pascal(name)}';

  Set<String> _collectDeps(SelectionSetNode set) {
    final deps = <String>{};
    for (final sel in set.selections) {
      if (sel is FragmentSpreadNode) {
        deps.add(_pref(sel.name.value));
      } else if (sel is InlineFragmentNode) {
        deps.addAll(_collectDeps(sel.selectionSet));
      } else if (sel is FieldNode && sel.selectionSet != null) {
        deps.addAll(_collectDeps(sel.selectionSet!));
      }
    }
    return deps;
  }
}
