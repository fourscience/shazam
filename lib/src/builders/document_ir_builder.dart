import 'package:shazam/src/builders/builder.dart';
import 'package:shazam/src/builders/fragment_builder.dart';
import 'package:shazam/src/builders/input_builder.dart';
import 'package:shazam/src/builders/ir_build_context.dart';
import 'package:shazam/src/builders/operation_builder.dart';
import 'package:shazam/src/builders/record_builder.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:shazam/src/operations_loader.dart';

/// High-level coordinator to build a complete Document IR from a parsed source.
class DocumentIrBuilder with Builder<DocumentIr, DocumentSource> {
  DocumentIrBuilder(this.context)
      : naming = NamingHelper(context.config),
        typeHelper = const TypeHelper();

  final IrBuildContext context;
  final NamingHelper naming;
  final TypeHelper typeHelper;

  @override
  DocumentIr build(DocumentSource source,
      {Iterable<DocumentSource> allSources = const []}) {
    late final RecordBuilder recordBuilder;
    late final FragmentBuilder fragmentBuilder;
    recordBuilder = RecordBuilder(context,
        resolveFragment: (name) => fragmentBuilder.build(name).record);
    fragmentBuilder = FragmentBuilder(context, recordBuilder);
    final sourcesToIndex = allSources.isNotEmpty ? allSources : [source];
    for (final src in sourcesToIndex) {
      fragmentBuilder.indexDefinitions(src);
    }

    final opBuilder = OperationBuilder(context, recordBuilder, fragmentBuilder);
    opBuilder.build(source);

    final inputBuilder = InputBuilder(context);
    final inputRecords = inputBuilder.buildAll();
    _wrapRecursiveInputFields(inputRecords);

    // Ensure all fragment definitions are materialized, even if unused.
    for (final name in fragmentBuilder.fragmentDefinitions.keys) {
      fragmentBuilder.build(name);
    }

    final fragments = fragmentBuilder.fragments.values
        .where((f) => fragmentBuilder.definitionOrigins[f.name] == source.path)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final operations = opBuilder.operations.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final records = [
      ...recordBuilder.records.values,
      ...inputRecords,
      ...opBuilder.variableRecords,
    ]..sort((a, b) => a.name.compareTo(b.name));
    final enums = context.schema.enums.values
        .map((e) => EnumIr(
              name: _pref(e.name.value),
              values: e.values.map((v) => v.name.value).toList(),
              description: context.docs.typeDescription(e.name.value),
              valueDescriptions: {
                for (final v in e.values)
                  v.name.value:
                      context.docs.enumValueDescription(e.name.value, v.name.value)
              },
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DocumentIr(
      path: source.path,
      operations: operations,
      fragments: fragments,
      records: records,
      interfaceImplementations: context.schemaIndex.interfaceImplementations(),
      unionVariants: context.schemaIndex.unionVariants(),
      enums: enums,
      operationOrigins: {
        for (final op in operations) op.name: source.path,
      },
      fragmentOrigins: fragmentBuilder.definitionOrigins,
    );
  }

  String _pref(String name) =>
      '${context.config.namePrefix}${naming.pascal(name)}';

  void _wrapRecursiveInputFields(List<RecordIr> inputs) {
    final inputNames = inputs.map((r) => r.name).toSet();
    final deps = <String, Set<String>>{};
    for (final record in inputs) {
      final targets = <String>{};
      for (final field in record.fields.values) {
        final core = typeHelper.coreType(field.type);
        if (inputNames.contains(core)) targets.add(core);
      }
      deps[record.name] = targets;
    }

    final cycles = _findCycles(inputNames, deps);
    if (cycles.isEmpty) return;

    for (final record in inputs) {
      if (!cycles.contains(record.name)) continue;
      for (final entry in record.fields.entries) {
        final core = typeHelper.coreType(entry.value.type);
        if (cycles.contains(core)) {
          final wrappedType = typeHelper.wrapThunk(entry.value.type);
          record.fields[entry.key] = FieldIr(
            name: entry.value.name,
            jsonKey: entry.value.jsonKey,
            sourceName: entry.value.sourceName,
            type: wrappedType,
            nullable: entry.value.nullable,
            thunkTarget: entry.value.type,
          );
        }
      }
    }
  }

  Set<String> _findCycles(Set<String> nodes, Map<String, Set<String>> edges) {
    final visiting = <String>[];
    final visited = <String>{};
    final cyc = <String>{};

    void dfs(String node) {
      if (visited.contains(node)) return;
      if (visiting.contains(node)) {
        final start = visiting.indexOf(node);
        cyc.addAll(visiting.sublist(start));
        return;
      }
      visiting.add(node);
      for (final next in edges[node] ?? const <String>{}) {
        dfs(next);
      }
      visiting.removeLast();
      visited.add(node);
    }

    for (final n in nodes) {
      dfs(n);
    }
    return cyc;
  }
}
