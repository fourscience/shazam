import 'dart:convert';
import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';
import 'package:shazam/src/emitters/enum_emitter.dart';
import 'package:shazam/src/emitters/operation_emitter.dart';
import 'package:shazam/src/emitters/record_emitter.dart';
import 'package:shazam/src/emitters/serializer_emitter.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/ir/ir.dart';
import 'package:shazam/src/log.dart';
import 'package:shazam/src/naming_helper.dart';

/// Contract for rendering a document IR into generated outputs.
abstract class Renderer {
  Future<void> render(
      DocumentIr ir, Config config, List<PluginRegistration> plugins);

  Future<void> renderShared(
      DocumentIr ir, Config config, List<PluginRegistration> plugins);
}

/// Default renderer that produces Dart files using code_builder.
// ignore_for_file: unused_element
class CodeRenderer implements Renderer {
  CodeRenderer(this.config);

  final Config config;
  late final TypeHelper _typeHelper = const TypeHelper();
  late final NamingHelper _naming = NamingHelper(config);
  late final Map<String, ScalarConfig> _scalarBySymbol =
      _scalarSymbolMap(config);
  late final SerializerEmitter _serializerEmitter =
      SerializerEmitter(_typeHelper, _scalarBySymbol);
  late final RecordEmitter _recordEmitter =
      RecordEmitter(_typeHelper, _serializerEmitter);
  late final EnumEmitter _enumEmitter = EnumEmitter();
  late final OperationEmitter _operationEmitter =
      OperationEmitter(config, _typeHelper);
  late final String _schemaLibPath =
      p.normalize(p.join(p.dirname(config.schemaPath), 'schema.dart'));

  @override
  Future<void> render(
      DocumentIr ir, Config _config, List<PluginRegistration> plugins) {
    return _emitDocument(ir, plugins);
  }

  @override
  Future<void> renderShared(
          DocumentIr ir, Config _config, List<PluginRegistration> plugins) =>
      _renderSharedHelpers(ir);

  Future<void> _emitDocument(
      DocumentIr ir, List<PluginRegistration> plugins) async {
    final outRoot = _outputRootFor(ir.path);
    // ignore: prefer_const_constructors, reason: 'Output path/config known only at runtime.'
    final renderCtx = RenderContext(outputRoot: outRoot, config: config);
    final pluginCtx = CodegenContext(
      ir: ir,
      render: renderCtx,
      config: config,
      services: const PluginServices(logInfo: logInfo, logWarn: logWarn),
    );
    final scalarBySymbol = _scalarBySymbol;

    for (final registration in plugins) {
      final manifest = registration.manifest;
      if (!manifest.capabilities.contains(PluginCapability.document)) continue;
      final hasMatchingOperation = ir.operations
          .any((op) => manifest.allowsOperation(op.name));
      final hasMatchingFragment =
          ir.fragments.any((frag) => manifest.allowsFragment(frag.name));
      if (manifest.operationFilter != null && !hasMatchingOperation) continue;
      if (manifest.fragmentFilter != null && !hasMatchingFragment) continue;
      registration.plugin.onDocument(pluginCtx);
    }
    final operationsDir = Directory(outRoot)..createSync(recursive: true);
    final fragmentsDir = operationsDir;

    final recordsByName = <String, RecordIr>{};
    for (final r in ir.records) {
      recordsByName.putIfAbsent(r.name, () => r);
    }
    final uniqueRecords = recordsByName.values.toList();
    final recordNames = uniqueRecords.map((r) => r.name).toSet();
    final enumNames = ir.enums.map((e) => e.name).toSet();
    final fragmentOwners = ir.fragments.map((f) => f.name).toSet();
    final fragmentRecords =
        uniqueRecords.where((r) => fragmentOwners.contains(r.owner)).toList();
    final opRecords = <String, List<RecordIr>>{};
    for (final record in uniqueRecords) {
      if (record.owner != null && !fragmentOwners.contains(record.owner)) {
        opRecords.putIfAbsent(record.owner!, () => []).add(record);
      }
    }
    final otherRecords = uniqueRecords
        .where((r) {
          final owner = r.owner;
          return owner == null ||
              (!fragmentOwners.contains(owner) && !opRecords.containsKey(owner));
        })
        .toList();
    final fragmentRecordOwners = {
      for (final r in fragmentRecords) r.name: r.owner
    };
    final schemaBuilder = LibraryBuilder()
      ..directives
          .addAll(_scalarImportsForRecords(otherRecords, scalarBySymbol))
      ..body.add(const Code('// Generated schema types\n'));
    for (final enm in ir.enums) {
      schemaBuilder.body.add(_enumEmitter.emitEnum(enm));
    }
    for (final record in otherRecords) {
      schemaBuilder.body
          .addAll(_recordEmitter.emitRecord(record, recordNames, enumNames));
    }
    await _writeLibrary(_schemaLibPath, schemaBuilder.build());

    for (final op in ir.operations) {
      final opOwned = opRecords[op.name] ?? const [];
      final opFilePath = p.join(operationsDir.path, '${op.name}.dart');
      final fragmentImports = {
        for (final frag in op.fragments)
          frag: _fragmentImportPath(frag, opFilePath, ir.fragmentOrigins)
      };
      final builder = LibraryBuilder()
        ..directives.addAll(_operationEmitter.directivesForOperation(
            ownedRecords: opOwned,
            fragmentRecordOwners: fragmentRecordOwners,
            fragments: op.fragments,
            schemaImport: _relativeSchemaImport(
                p.join(operationsDir.path, '${op.name}.dart')),
            scalarTypes: scalarBySymbol,
            fragmentImportPaths: fragmentImports,
            fragmentsPrefix: '',
            helpersImport:
                p.relative(_helpersPath, from: p.dirname(opFilePath))))
        ..body.add(const Code('\n// Generated by shazam\n'))
        ..body.add(Code(_operationEmitter.operationConst(op.name, op.node)))
        ..body.add(Code(
            '\n${_operationEmitter.operationRequest(op.name, op.variableRecord?.name, op.variableDefaults)}'))
        ..body.add(Code('\n${_operationEmitter.operationParse(op)}'));
      for (final record in opOwned) {
        builder.body
            .addAll(_recordEmitter.emitRecord(record, recordNames, enumNames));
      }
      final eligible = plugins.where((p) =>
          p.manifest.capabilities.contains(PluginCapability.library) &&
          p.manifest.allowsOperation(op.name));
      for (final plugin in eligible) {
        plugin.plugin.onLibrary(builder, pluginCtx);
      }
      await _writeLibrary(
          p.join(operationsDir.path, '${op.name}.dart'), builder.build());
    }

    for (final frag in ir.fragments) {
      final fragFilePath = p.join(fragmentsDir.path, '${frag.name}.dart');
      final builder = LibraryBuilder()
        ..directives.addAll(
            _fragmentImports(frag, fragmentRecords, fragmentRecordOwners,
                fragFilePath, ir.fragmentOrigins))
        ..directives.add(Directive.import(_relativeSchemaImport(
            fragFilePath)))
        ..directives.addAll(_scalarImportsForRecords(
            fragmentRecords.where((r) => r.owner == frag.name).toList(),
            scalarBySymbol))
        ..body.add(const Code('\n// Generated by shazam\n'))
        ..body.add(Code(_fragmentConst(frag.name, frag.node)));
      final owned = fragmentRecords.where((r) => r.owner == frag.name);
      for (final record in owned) {
        builder.body
            .addAll(_recordEmitter.emitRecord(record, recordNames, enumNames));
      }
      final eligible = plugins.where((p) =>
          p.manifest.capabilities.contains(PluginCapability.library) &&
          p.manifest.allowsFragment(frag.name));
      for (final plugin in eligible) {
        plugin.plugin.onLibrary(builder, pluginCtx);
      }
      await _writeLibrary(
          p.join(fragmentsDir.path, '${frag.name}.dart'), builder.build());
    }

    for (final plugin in plugins) {
      if (!plugin.manifest.capabilities
          .contains(PluginCapability.renderComplete)) {
        continue;
      }
      plugin.plugin.onRenderComplete(pluginCtx);
    }
    logInfo('Wrote outputs to $outRoot');
  }

  String _operationConst(String name, OperationDefinitionNode node) {
    final source = printNode(node);
    final prefix = () {
      switch (node.type) {
        case OperationType.query:
          return 'query';
        case OperationType.mutation:
          return 'mutate';
        case OperationType.subscription:
          return 'subscribe';
      }
    }();
    final opName = '$prefix${_naming.pascal(name)}';
    final withName = _injectOperationName(source, opName);
    if (config.compressQueries) {
      final compressed = base64Encode(gzip.encode(utf8.encode(withName)));
      final constName = '${config.namePrefix}${name}OperationCompressed';
      final getterName = '${config.namePrefix}${name}Operation';
      return "const $constName = '$compressed';\nString get $getterName => decompress($constName);";
    }
    return "const ${config.namePrefix}${name}Operation = r'''$withName''';";
  }

  String _operationRequest(String name, String? variableRecord) {
    final opConst = '${config.namePrefix}${name}Operation';
    final builderName = 'build${config.namePrefix}${name}Request';
    if (variableRecord == null) {
      return '''
Map<String, dynamic> $builderName({Map<String, dynamic>? variables}) {
  return {
    'query': $opConst,
    if (variables != null) 'variables': variables,
  };
}
''';
    }
    return '''
Map<String, dynamic> $builderName({$variableRecord? variables}) {
  return {
    'query': $opConst,
    if (variables != null) 'variables': serialize$variableRecord(variables),
  };
}
''';
  }

  String _operationParse(OperationIr op) {
    final parseName = 'parse${config.namePrefix}${op.name}Response';
    final recordType = op.record.name;
    return '''
$recordType $parseName(Map<String, dynamic> json) {
  return deserialize$recordType(json);
}
''';
  }

  String _fragmentConst(String name, FragmentDefinitionNode node) {
    final source = printNode(node);
    return "const ${config.namePrefix}${name}Fragment = r'''$source''';";
  }

  String _typeHelpers(DocumentIr ir) {
    final interfaceMap = _emitTypeMap(ir.interfaceImplementations);
    final unionMap = _emitTypeMap(ir.unionVariants);
    return '''
const _interfaceImpls = <String, Set<String>>{
$interfaceMap};

const _unionVariants = <String, Set<String>>{
$unionMap};

bool isTypeName(dynamic record, String expected) {
  final typeName = (record as dynamic).typeName;
  return typeName == expected;
}

/// Checks if a record matches a concrete type, interface, or union name.
bool isTypeOf(dynamic record, String target) {
  final typeName = (record as dynamic).typeName;
  if (typeName == target) return true;
  final impls = _interfaceImpls[target];
  if (impls != null && impls.contains(typeName)) return true;
  final variants = _unionVariants[target];
  if (variants != null && variants.contains(typeName)) return true;
  return false;
}
''';
  }

  String _serializerRegistry(DocumentIr ir) {
    final buffer = StringBuffer()
      ..writeln('typedef ResponseParser<T> = T Function(Map<String, dynamic>);')
      ..writeln(
          'final responseParsers = <String, dynamic Function(Map<String, dynamic>)>{');
    for (final op in ir.operations) {
      final key = '${config.namePrefix}${op.name}';
      final parseName = 'parse${config.namePrefix}${op.name}Response';
      buffer.writeln("  '$key': $parseName,");
    }
    buffer.writeln('};');
    
    buffer.writeln(
        'dynamic Function(Map<String, dynamic>)? resolveParser(String key) => responseParsers[key];');
    return buffer.toString();
  }

  String _injectOperationName(String source, String name) {
    final trimmed = source.trimLeft();
    if (trimmed.startsWith('query ') ||
        trimmed.startsWith('mutation ') ||
        trimmed.startsWith('subscription ')) {
      // Already named; leave as-is.
      return source;
    }
    final opType = trimmed.split(RegExp(r'\\s+')).first;
    final rest = trimmed.substring(opType.length).trimLeft();
    return '$opType $name $rest';
  }

  String _emitTypeMap(Map<String, Set<String>> map) {
    final buffer = StringBuffer();
    for (final entry in map.entries) {
      final values = entry.value.map((e) => "'$e'").join(', ');
      buffer.writeln("  '${entry.key}': {$values},");
    }
    return buffer.toString();
  }

  String _outputRootFor(String sourcePath) {
    final dir = p.dirname(sourcePath);
    return p.join(dir, config.outputDir);
  }

  String _fragmentImportPath(
      String name, String fromFile, Map<String, String> origins) {
    final origin = origins[name];
    if (origin == null || origin.isEmpty) {
      return '../fragments/$name.dart';
    }
    final targetRoot = _outputRootFor(origin);
    final target = p.join(targetRoot, 'fragments', '$name.dart');
    return p.relative(target, from: p.dirname(fromFile));
  }

  String get _helpersPath =>
      p.join(p.dirname(_schemaLibPath), 'graphql.g.dart');

  Spec _emitEnum(EnumIr enm) {
    return Enum((b) {
      b
        ..name = enm.name
        ..values.addAll(
            enm.values.map((v) => EnumValue((ev) => ev..name = _enumCase(v))));
    });
  }

  String _enumCase(String name) {
    // Keep uppercase GraphQL enums as valid Dart identifiers; fallback to camel.
    // ignore: unnecessary_raw_strings, reason: 'Raw regexp keeps escapes minimal.'
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (RegExp(r'^[A-Z0-9_]+$').hasMatch(cleaned)) {
      return cleaned;
    }
    final parts = cleaned.split(RegExp(r'[_\s]+'));
    final camel = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join();
    return camel.isEmpty
        ? 'value'
        : camel[0].toLowerCase() + camel.substring(1);
  }

  List<Directive> _importsForRecords(
      List<RecordIr> records, Map<String, String?> fragmentRecordOwners,
      {String prefix = 'fragments/'}) {
    final owners = <String>{};

    String? resolveOwner(String type) {
      final core = _typeHelper.coreType(type);
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

  Map<String, ScalarConfig> _scalarSymbolMap(Config config) {
    final result = <String, ScalarConfig>{};
    for (final entry in config.scalarMapping.entries) {
      result[entry.value.symbol] = entry.value;
    }
    return result;
  }

  List<Directive> _scalarImportsForRecords(
      List<RecordIr> records, Map<String, ScalarConfig> scalarTypes) {
    final imports = <String>{};
    for (final record in records) {
      for (final field in record.fields.values) {
        final scalar = scalarTypes[_typeHelper.coreType(field.type)];
        if (scalar != null && scalar.hasImport) {
          imports.add(scalar.import!);
        }
      }
    }
    return imports.map(Directive.import).toList();
  }

  String _relativeSchemaImport(String fromFile) =>
      p.relative(_schemaLibPath, from: p.dirname(fromFile));

  Future<void> _renderSharedHelpers(DocumentIr ir) async {
    final helpersPath = _helpersPath;
    final helpersBuilder = LibraryBuilder()
      ..directives.addAll([
        Directive.import('dart:convert'),
        Directive.import('dart:io', show: const ['gzip']),
        ...ir.operations
            .map((op) => Directive.import(_operationImportPath(ir, op.name))),
      ])
      ..body.add(const Code('\n// Generated helpers\n'))
      ..body.add(const Code(
          'String decompress(String input) => utf8.decode(gzip.decode(base64Decode(input)));'))
      ..body.add(Code(_typeHelpers(ir)))
      ..body.add(Code(_serializerRegistry(ir)));
    await _writeLibrary(helpersPath, helpersBuilder.build());
  }

  String _operationImportPath(DocumentIr ir, String opName) {
    final origin = ir.operationOrigins[opName];
    if (origin == null) {
      return '${opName}.dart';
    }
    final opPath = p.join(_outputRootFor(origin), '$opName.dart');
    return p.relative(opPath, from: p.dirname(_helpersPath));
  }

  List<Directive> _fragmentImports(
      FragmentIr frag,
      List<RecordIr> fragmentRecords,
      Map<String, String?> fragmentOwners,
      String fromFile,
      Map<String, String> fragmentOrigins) {
    final owned = fragmentRecords.where((r) => r.owner == frag.name);
    final owners = <String>{};

    for (final record in owned) {
      for (final field in record.fields.values) {
        final owner = fragmentOwners[_typeHelper.coreType(field.type)];
        if (owner != null && owner != frag.name) {
          owners.add(owner);
        }
      }
    }

    return owners
        .map((name) =>
            Directive.import(_fragmentImportPath(name, fromFile, fragmentOrigins)))
        .toList();
  }

  Future<void> _writeLibrary(String path, Library library) async {
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
    final source = library.accept(emitter).toString();
    String formatted;
    try {
      formatted = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(source);
    } on FormatterException catch (e) {
      await File('$path.raw').writeAsString(source);
      logError('Formatting failed for $path: ${e.message()}');
      rethrow;
    }
    await File(path).create(recursive: true);
    await File(path).writeAsString(formatted);
  }
}
