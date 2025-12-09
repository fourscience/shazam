import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator.dart';
import 'package:shazam/src/log.dart';
import 'package:shazam/src/watcher.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('watch', abbr: 'w', defaultsTo: false, help: 'Watch for changes')
    ..addOption('config',
        abbr: 'c', defaultsTo: 'config.yaml', help: 'Path to config file');

  if (args.isEmpty) {
    _printUsage(parser);
    exitCode = 64;
    return;
  }

  final command = args.first;
  final parsed = parser.parse(args.skip(1));

  switch (command) {
    case 'build':
      await _runBuild(parsed['config'] as String,
          watch: parsed['watch'] as bool);
      break;
    case 'help':
      _printUsage(parser);
      break;
    default:
      logError('Unknown command: $command');
      _printUsage(parser);
      exitCode = 64;
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: dart run shazam build [--config <path>] [--watch]');
  stdout.writeln(parser.usage);
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
