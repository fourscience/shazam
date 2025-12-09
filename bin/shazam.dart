import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gql/ast.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator.dart';
import 'package:shazam/src/log.dart';
import 'package:shazam/src/operations_loader.dart';
import 'package:shazam/src/schema.dart';
import 'package:shazam/src/shazam_watcher.dart';

Future<void> main(List<String> args) async {
  final runner = Shazam();
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  }
}

Future<void> _runBuild(String configPath, {required bool watch}) async {
  final configFile = File(configPath);
  if (!configFile.existsSync()) {
    logWarn('Config not found at $configPath; using defaults');
  }
  final config = await Config.load(configFile);

  Future<void> buildOnce() async {
    final generator = Generator(config);
    await generator.build();
  }

  await buildOnce();

  if (watch) {
    logInfo('Entering watch mode');
    final watcher = ShazamWatcher(config, onChange: buildOnce);
    await watcher.start();
  }
}

Future<void> _runList(String configPath) async {
  final configFile = File(configPath);
  if (!configFile.existsSync()) {
    logError('Config not found at $configPath');
    exitCode = 64;
    return;
  }
  final config = await Config.load(configFile);

  final schemaFile = File(config.schemaPath);
  if (!schemaFile.existsSync()) {
    logError('Schema not found at ${config.schemaPath}');
    exitCode = 64;
    return;
  }

  late final Schema schema;
  try {
    schema = Schema.parse(await schemaFile.readAsString());
  } on Exception catch (e) {
    logError('Failed to parse schema at ${config.schemaPath}: $e');
    exitCode = 1;
    return;
  }

  final loader = OperationsLoader(inputDir: config.inputDir);
  late final OperationsBundle bundle;
  try {
    bundle = await loader.load();
  } on Exception catch (e) {
    logError('Failed to read operations from ${config.inputDir}: $e');
    exitCode = 1;
    return;
  }

  _printOperations(bundle);
  _printScalars(schema, config);
}

void _printOperations(OperationsBundle bundle) {
  final operations = <String>[];
  final fragments = <String>[];

  for (final doc in bundle.documents) {
    for (final def in doc.document.definitions) {
      if (def is OperationDefinitionNode) {
        final opName = def.name?.value ?? '<anonymous ${def.type.name}>';
        operations.add('$opName (${def.type.name}) from ${doc.path}');
      } else if (def is FragmentDefinitionNode) {
        fragments.add('${def.name.value} (fragment) from ${doc.path}');
      }
    }
  }

  logInfo('Operations (${operations.length}):');
  if (operations.isEmpty) {
    stdout.writeln('  (none found under configured input_dir)');
  } else {
    for (final op in operations..sort()) {
      stdout.writeln('  - $op');
    }
  }

  logInfo('Fragments (${fragments.length}):');
  if (fragments.isEmpty) {
    stdout.writeln('  (none found under configured input_dir)');
  } else {
    for (final frag in fragments..sort()) {
      stdout.writeln('  - $frag');
    }
  }
}

void _printScalars(Schema schema, Config config) {
  const builtIns = {'String', 'ID', 'Int', 'Float', 'Boolean'};
  final scalars = schema.scalars.toList()..sort();
  final customScalars = scalars.where((s) => !builtIns.contains(s)).toList();
  final unmappedCustom =
      customScalars.where((s) => !config.scalarMapping.containsKey(s)).toList();
  final unusedMappings = config.scalarMapping.keys
      .where((name) => !schema.scalars.contains(name))
      .toList()
    ..sort();

  logInfo('Scalars (${scalars.length}):');
  for (final scalar in scalars) {
    final mapping = config.scalarMapping[scalar];
    if (mapping != null) {
      final import = mapping.import;
      final importSuffix =
          (import != null && import.isNotEmpty) ? ' (import: $import)' : '';
      stdout.writeln(
          '  - $scalar -> ${mapping.symbol}${importSuffix.isEmpty ? '' : importSuffix}');
    } else if (builtIns.contains(scalar)) {
      stdout.writeln('  - $scalar (built-in)');
    } else {
      stdout.writeln('  - $scalar (unmapped custom scalar)');
    }
  }

  if (unmappedCustom.isNotEmpty) {
    logWarn(
        'Custom scalars without mapping: ${unmappedCustom.join(', ')} (configure them under "scalars")');
  }
  if (unusedMappings.isNotEmpty) {
    logWarn(
        'Scalar mappings not present in schema: ${unusedMappings.join(', ')}');
  }
}

class Shazam extends CommandRunner<void> {
  Shazam()
      : super('shazam', 'GraphQL codegen for Dart (build, list, and watch).') {
    addCommand(_BuildCommand());
    addCommand(_ListCommand());
  }

  @override
  Future<void> run(Iterable<String> args) {
    if (args.isEmpty) {
      printUsage();
      exitCode = 64;
      return Future<void>.value();
    }
    return super.run(args);
  }
}

class _BuildCommand extends Command<void> {
  _BuildCommand() {
    argParser
      ..addOption('config',
          abbr: 'c', defaultsTo: 'config.yaml', help: 'Path to config file')
      ..addFlag('watch',
          abbr: 'w', defaultsTo: false, help: 'Watch for changes');
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Generate Dart code for the configured schema/ops.';

  @override
  Future<void> run() async {
    final configPath = argResults?['config'] as String? ?? 'config.yaml';
    final watch = argResults?['watch'] as bool? ?? false;
    await _runBuild(configPath, watch: watch);
  }
}

class _ListCommand extends Command<void> {
  _ListCommand() {
    argParser.addOption('config',
        abbr: 'c', defaultsTo: 'config.yaml', help: 'Path to config file');
  }

  @override
  String get name => 'list';

  @override
  String get description =>
      'List operations, fragments, and scalar mappings for the config.';

  @override
  Future<void> run() async {
    final configPath = argResults?['config'] as String? ?? 'config.yaml';
    await _runList(configPath);
  }
}
