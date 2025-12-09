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

  String _pref(String name) =>
      '${context.config.namePrefix}${_pascal(name)}';

  String _pascal(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .map((part) =>
            part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join();
  }
}
