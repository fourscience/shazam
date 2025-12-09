import 'dart:convert';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

import 'package:shazam/src/config.dart';
import 'package:shazam/src/document_ir.dart';
import 'package:shazam/src/naming_helper.dart';

class OperationEmitter {
  OperationEmitter(this.config, this.typeHelper);

  final Config config;
  final TypeHelper typeHelper;

  List<Directive> directivesForOperation({
    required List<RecordIr> ownedRecords,
    required Map<String, String?> fragmentRecordOwners,
    required Iterable<String> fragments,
    required String schemaImport,
    required Map<String, ScalarConfig> scalarTypes,
  }) {
    return [
      if (config.compressQueries) Directive.import('../helpers.dart'),
      Directive.import(schemaImport),
      ...importsForRecords(ownedRecords, fragmentRecordOwners,
          prefix: '../fragments/'),
      ...fragments.map((f) => Directive.import('../fragments/$f.dart')),
      ...scalarImportsForRecords(ownedRecords, scalarTypes),
    ];
  }

  List<Directive> directivesForFragment({
    required FragmentIr fragment,
    required List<RecordIr> fragmentRecords,
    required Map<String, String?> fragmentOwners,
    required String schemaImport,
    required Map<String, ScalarConfig> scalarTypes,
  }) {
    return [
      ...fragmentImports(fragment, fragmentRecords, fragmentOwners),
      Directive.import(schemaImport),
      ...scalarImportsForRecords(
          fragmentRecords.where((r) => r.owner == fragment.name).toList(),
          scalarTypes),
    ];
  }

  String operationConst(String name, OperationDefinitionNode node) {
    final source = printNode(node);
    final prefix = switch (node.type) {
      OperationType.query => 'query',
      OperationType.mutation => 'mutate',
      OperationType.subscription => 'subscribe'
    };

    final opName =
        '$prefix${config.namePrefix}${name.isEmpty ? '' : name.toPascalCase()}';
    final withName = _injectOperationName(source, opName);
    if (config.compressQueries) {
      final compressed = base64Encode(gzip.encode(utf8.encode(withName)));
      final constName = '${config.namePrefix}${name}OperationCompressed';
      final getterName = '${config.namePrefix}${name}Operation';
      return "const $constName = '$compressed';\nString get $getterName => decompress($constName);";
    }
    return "const ${config.namePrefix}${name}Operation = r'''$withName''';";
  }

  String operationRequest(
      String name, String? variableRecord, Map<String, Object?> defaults) {
    final opConst = '${config.namePrefix}${name}Operation';
    final builderName = 'build${config.namePrefix}${name}Request';
    final hasDefaults = defaults.isNotEmpty;
    final defaultsLiteral =
        hasDefaults ? jsonEncode(defaults) : '<String, dynamic>{}';
    if (variableRecord == null) {
      return '''
Map<String, dynamic> $builderName(
    {Map<String, dynamic>? variables, String? operationName}) {
  final _vars = <String, dynamic>${hasDefaults ? defaultsLiteral : '{}'};
  if (variables != null) _vars.addAll(variables);
  return {
    'query': $opConst,
    if (operationName != null) 'operationName': operationName,
    if (_vars.isNotEmpty) 'variables': _vars,
  };
}
''';
    }
    return '''
Map<String, dynamic> $builderName(
    {$variableRecord? variables, String? operationName}) {
  final _vars = <String, dynamic>${hasDefaults ? defaultsLiteral : '{}'};
  if (variables != null) {
    _vars.addAll(serialize$variableRecord(variables));
  }
  return {
    'query': $opConst,
    if (operationName != null) 'operationName': operationName,
    if (_vars.isNotEmpty) 'variables': _vars,
  };
}
''';
  }

  String operationParse(OperationIr op) {
    final parseName = 'parse${config.namePrefix}${op.name}Response';
    final recordType = op.record.name;
    return '''
$recordType $parseName(Map<String, dynamic> json) => deserialize$recordType(json);
''';
  }

  String fragmentConst(String name, FragmentDefinitionNode node) {
    final source = printNode(node);
    return "const ${config.namePrefix}${name}Fragment = r'''$source''';";
  }

  List<Directive> importsForRecords(
      List<RecordIr> records, Map<String, String?> fragmentRecordOwners,
      {String prefix = 'fragments/'}) {
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

    return owners.map((o) => Directive.import('$prefix$o.dart')).toList();
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

  List<Directive> fragmentImports(FragmentIr frag,
      List<RecordIr> fragmentRecords, Map<String, String?> fragmentOwners) {
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
        .map((name) => Directive.import('../fragments/$name.dart'))
        .toList();
  }

  String _injectOperationName(String source, String name) {
    final trimmed = source.trimLeft();
    if (trimmed.startsWith('query ') ||
        trimmed.startsWith('mutation ') ||
        trimmed.startsWith('subscription ')) {
      return source;
    }
    final opType = trimmed.split(RegExp(r'\\s+')).first;
    final rest = trimmed.substring(opType.length).trimLeft();
    return '$opType $name $rest';
  }
}
