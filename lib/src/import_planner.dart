import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/emission_context.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/naming_helper.dart';

/// Resolves imports and paths for emitted libraries to keep the renderer lean.
class ImportPlanner {
  ImportPlanner(this.context, this.typeHelper);

  final EmissionContext context;
  final TypeHelper typeHelper;

  List<Directive> metaImportIfNeeded({
    Iterable<RecordIr> records = const [],
    Iterable<EnumIr> enums = const [],
  }) {
    final hasDeprecatedField = records.any((r) =>
        r.fields.values.any((f) => f.deprecatedReason != null));
    final hasDeprecatedEnum =
        enums.any((e) => e.valueDeprecations.values.any((v) => v != null));
    if (hasDeprecatedField || hasDeprecatedEnum) {
      return [Directive.import('package:meta/meta.dart')];
    }
    return const [];
  }

  List<Directive> directivesForOperation({
    required List<RecordIr> ownedRecords,
    required Map<String, String?> fragmentRecordOwners,
    required Iterable<String> fragments,
    required String fromFile,
    required Map<String, ScalarConfig> scalarTypes,
    required String helpersImport,
    Map<String, String>? fragmentImportPaths,
    String fragmentsPrefix = '../fragments/',
  }) {
    final directives = <Directive>[
      if (context.config.compressQueries) Directive.import(helpersImport),
      Directive.import(context.relativeSchemaImport(fromFile)),
      ..._importsForRecords(ownedRecords, fragmentRecordOwners,
          prefix: fragmentsPrefix, fragmentImportPaths: fragmentImportPaths),
      ...fragments.map((f) {
        final path = fragmentImportPaths?[f] ??
            context.fragmentImportPath(f, fromFile);
        return Directive.import(path);
      }),
      ...scalarImportsForRecords(ownedRecords, scalarTypes),
    ];
    if (_hasDeprecatedRecords(ownedRecords)) {
      directives.insert(0, Directive.import('package:meta/meta.dart'));
    }
    return directives;
  }

  List<Directive> directivesForFragment({
    required FragmentIr fragment,
    required List<RecordIr> fragmentRecords,
    required Map<String, String?> fragmentOwners,
    required String fromFile,
    required Map<String, ScalarConfig> scalarTypes,
  }) {
    final directives = <Directive>[
      ..._fragmentImports(fragment, fragmentRecords, fragmentOwners, fromFile),
      Directive.import(context.relativeSchemaImport(fromFile)),
      ...scalarImportsForRecords(
          fragmentRecords.where((r) => r.owner == fragment.name).toList(),
          scalarTypes),
    ];
    final owned = fragmentRecords.where((r) => r.owner == fragment.name);
    if (_hasDeprecatedRecords(owned)) {
      directives.insert(0, Directive.import('package:meta/meta.dart'));
    }
    return directives;
  }

  List<Directive> _importsForRecords(
      List<RecordIr> records, Map<String, String?> fragmentRecordOwners,
      {String prefix = 'fragments/',
      Map<String, String>? fragmentImportPaths}) {
    final owners = <String>{};

    String? resolveOwner(String type) {
      final core = typeHelper.coreType(type);
      return fragmentRecordOwners[core];
    }

    for (final record in records) {
      for (final field in record.fields.values) {
        final owner = resolveOwner(field.type);
        if (owner != null) owners.add(owner);
      }
    }

    return owners
        .map((o) => Directive.import(
            fragmentImportPaths != null && fragmentImportPaths.containsKey(o)
                ? fragmentImportPaths[o]!
                : '$prefix$o.dart'))
        .toList();
  }

  List<Directive> scalarImportsForRecords(
      List<RecordIr> records, Map<String, ScalarConfig> scalarTypes) {
    final imports = <String>{};
    for (final record in records) {
      for (final field in record.fields.values) {
        final scalar = scalarTypes[typeHelper.coreType(field.type)];
        if (scalar != null && scalar.hasImport) {
          imports.add(scalar.import!);
        }
      }
    }
    return imports.map(Directive.import).toList();
  }

  List<Directive> _fragmentImports(FragmentIr frag, List<RecordIr> fragmentRecords,
      Map<String, String?> fragmentOwners, String fromFile) {
    final owned = fragmentRecords.where((r) => r.owner == frag.name);
    final owners = <String>{};

    for (final record in owned) {
      for (final field in record.fields.values) {
        final owner = fragmentOwners[typeHelper.coreType(field.type)];
        if (owner != null && owner != frag.name) {
          owners.add(owner);
        }
      }
    }

    return owners
        .map((name) => Directive.import(context.fragmentImportPath(name, fromFile)))
        .toList();
  }

  bool _hasDeprecatedRecords(Iterable<RecordIr> records) => records.any(
      (r) => r.fields.values.any((f) => f.deprecatedReason != null));
}
