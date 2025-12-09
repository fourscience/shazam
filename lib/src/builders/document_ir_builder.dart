import '../ir.dart';
import '../operations.dart';
import 'fragment_builder.dart';
import 'ir_context.dart';
import 'input_builder.dart';
import 'operation_builder.dart';
import 'record_builder.dart';

/// High-level coordinator to build a complete Document IR from a parsed source.
class DocumentIrBuilder {
  DocumentIrBuilder(this.context);

  final IrBuildContext context;

  DocumentIr build(DocumentSource source) {
    late final RecordBuilder recordBuilder;
    late final FragmentBuilder fragmentBuilder;
    recordBuilder = RecordBuilder(context,
        resolveFragment: (name) => fragmentBuilder.build(name).record);
    fragmentBuilder = FragmentBuilder(context, recordBuilder);
    fragmentBuilder.indexDefinitions(source);

    final opBuilder = OperationBuilder(context, recordBuilder, fragmentBuilder);
    opBuilder.build(source);

    final inputBuilder = InputBuilder(context);
    final inputRecords = inputBuilder.buildAll();
    _wrapRecursiveInputFields(inputRecords);

    // Ensure all fragment definitions are materialized, even if unused.
    for (final name in fragmentBuilder.fragmentDefinitions.keys) {
      fragmentBuilder.build(name);
    }

    final fragments = fragmentBuilder.fragments.values.toList()
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
    );
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

  void _wrapRecursiveInputFields(List<RecordIr> inputs) {
    final inputNames = inputs.map((r) => r.name).toSet();
    final deps = <String, Set<String>>{};
    for (final record in inputs) {
      final targets = <String>{};
      for (final field in record.fields.values) {
        final core = _coreType(field.type);
        if (inputNames.contains(core)) targets.add(core);
      }
      deps[record.name] = targets;
    }

    final cycles = _findCycles(inputNames, deps);
    if (cycles.isEmpty) return;

    for (final record in inputs) {
      if (!cycles.contains(record.name)) continue;
      for (final entry in record.fields.entries) {
        final core = _coreType(entry.value.type);
        if (cycles.contains(core)) {
          final wrappedType = _wrapThunk(entry.value.type);
          record.fields[entry.key] = FieldIr(
            name: entry.value.name,
            jsonKey: entry.value.jsonKey,
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
      for (final next in edges[node] ?? const {}) {
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

  String _coreType(String type) {
    var current = type;
    if (current.endsWith('?'))
      current = current.substring(0, current.length - 1);
    if (current.endsWith(' Function()')) {
      current = current.substring(0, current.length - ' Function()'.length);
    } else if (current.endsWith(' Function()?')) {
      current =
          current.substring(0, current.length - ' Function()?'.length) + '?';
    }
    while (current.startsWith('List<') && current.endsWith('>')) {
      current = current.substring(5, current.length - 1);
      if (current.endsWith('?')) {
        current = current.substring(0, current.length - 1);
      }
    }
    return current;
  }

  String _wrapThunk(String type) {
    final nullable = type.endsWith('?');
    return nullable ? '$type Function()?' : '$type Function()';
  }
}
