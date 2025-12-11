import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';
import 'package:shazam/src/emission_context.dart';
import 'package:shazam/src/emitters/document_emitter.dart';
import 'package:shazam/src/emitters/enum_emitter.dart';
import 'package:shazam/src/emitters/operation_emitter.dart';
import 'package:shazam/src/emitters/record_emitter.dart';
import 'package:shazam/src/emitters/registry_emitter.dart';
import 'package:shazam/src/emitters/serializer_emitter.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/import_planner.dart';
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
  late final Map<String, ScalarConfig> _scalarBySymbol =
      _scalarSymbolMap(config);
  late final SerializerEmitter _serializerEmitter =
      SerializerEmitter(_typeHelper, _scalarBySymbol);
  late final RecordEmitter _recordEmitter =
      RecordEmitter(_typeHelper, _serializerEmitter);
  late final EnumEmitter _enumEmitter = EnumEmitter();
  late final OperationEmitter _operationEmitter =
      OperationEmitter(config, _typeHelper);
  late final RegistryEmitter _registryEmitter = RegistryEmitter(config);
  final Map<String, RecordIr> _schemaRecordsAggregate = {};
  final Map<String, EnumIr> _schemaEnumsAggregate = {};
  @override
  Future<void> render(
      DocumentIr ir, Config _config, List<PluginRegistration> plugins) {
    return _emitDocument(ir, plugins);
  }

  @override
  Future<void> renderShared(
          DocumentIr ir, Config _config, List<PluginRegistration> plugins) =>
      _renderSharedHelpers(
          ir,
          EmissionContext(
            config: config,
            fragmentOrigins: ir.fragmentOrigins,
            operationOrigins: ir.operationOrigins,
          ));

  Future<void> _emitDocument(
      DocumentIr ir, List<PluginRegistration> plugins) async {
    final emissionCtx = EmissionContext(
      config: config,
      fragmentOrigins: ir.fragmentOrigins,
      operationOrigins: ir.operationOrigins,
    );
    final importPlanner = ImportPlanner(emissionCtx, _typeHelper);
    final documentEmitter = DocumentEmitter(
      importPlanner,
      _recordEmitter,
      _enumEmitter,
      _operationEmitter,
    );
    final outRoot = emissionCtx.outputRootFor(ir.path);
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
    for (final rec in uniqueRecords) {
      _schemaRecordsAggregate[rec.name] = rec;
    }
    for (final enm in ir.enums) {
      _schemaEnumsAggregate[enm.name] = enm;
    }

    final schemaRecords = _schemaRecordsAggregate.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final schemaEnums = _schemaEnumsAggregate.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final schemaBuilder = documentEmitter.schemaLibrary(
      records: schemaRecords,
      enums: schemaEnums,
      scalarTypes: scalarBySymbol,
      recordNames: recordNames,
      enumNames: enumNames,
    );
    await _writeLibrary(emissionCtx.schemaLibraryPath, schemaBuilder.build());

    for (final op in ir.operations) {
      final opOwned = opRecords[op.name] ?? const [];
      final opFilePath = p.join(operationsDir.path, '${op.name}.dart');
      final fragmentImports = {
        for (final frag in op.fragments)
          frag: emissionCtx.fragmentImportPath(frag, opFilePath)
      };
      final builder = documentEmitter.operationLibrary(
          operation: op,
          ownedRecords: opOwned,
          recordNames: recordNames,
          enumNames: enumNames,
          fragmentRecordOwners: fragmentRecordOwners,
          scalarTypes: scalarBySymbol,
          fragmentImports: fragmentImports,
          helpersImport:
              p.relative(emissionCtx.helpersPath, from: p.dirname(opFilePath)),
          fromFile: opFilePath);
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
      var ownedFragmentRecords = fragmentRecords
          .where((r) => r.owner == frag.name)
          .toList();
      if (ownedFragmentRecords.isEmpty) {
        ownedFragmentRecords = _schemaRecordsAggregate.values
            .where((r) => r.owner == frag.name)
            .toList();
      }
      final builder = documentEmitter.fragmentLibrary(
        fragment: frag,
        fragmentRecords: ownedFragmentRecords,
        recordNames:
            _schemaRecordsAggregate.values.map((r) => r.name).toSet(),
        enumNames: _schemaEnumsAggregate.values.map((e) => e.name).toSet(),
        fragmentOwners: fragmentRecordOwners,
        scalarTypes: scalarBySymbol,
        fromFile: fragFilePath,
      );
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

  Map<String, ScalarConfig> _scalarSymbolMap(Config config) {
    final result = <String, ScalarConfig>{};
    for (final entry in config.scalarMapping.entries) {
      result[entry.value.symbol] = entry.value;
    }
    return result;
  }

  Future<void> _renderSharedHelpers(
      DocumentIr ir, EmissionContext ctx) async {
    final helpersPath = ctx.helpersPath;
    final operationImports =
        ir.operations.map((op) => ctx.operationImportPath(op.name));
    final helpersLibrary =
        _registryEmitter.emitHelpers(ir, operationImports.toList());
    await _writeLibrary(helpersPath, helpersLibrary);
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
