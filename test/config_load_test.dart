import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';
import 'package:test/test.dart';

void main() {
  test('Config.load returns defaults when file is missing', () async {
    final missing = File(p.join(Directory.systemTemp.path, 'no_config.yaml'));
    final config = await Config.load(missing);

    expect(config.outputDir, 'generated');
    expect(config.inputDir, 'lib');
    expect(config.schemaPath, 'schema.graphql');
    expect(config.nullableMode, NullableMode.required);
    expect(config.logLevel, LogLevel.info);
  });

  test('Config.load parses scalar mappings, keyword replacements, and paths',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('config_load_');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final schemaPath = p.join(tempDir.path, 'schema.graphql');
    File(schemaPath).writeAsStringSync('type Query { noop: String }');
    final inputDir = Directory(p.join(tempDir.path, 'ops'))
      ..createSync(recursive: true);
    final pluginPath = p.join(tempDir.path, 'plugins', 'plugin.dart');
    File(pluginPath).createSync(recursive: true);

    final configFile = File(p.join(tempDir.path, 'config.yaml'));
    configFile.writeAsStringSync('''
output_dir: generated_out
input_dir: ops
nullable_mode: optional
name_prefix: Foo
compress_queries: false
emit_helpers: true
schema: schema.graphql
log_level: warn
scalars:
  DateTime: CustomDateTime
  Money:
    symbol: MoneyType
    import: package:money/money.dart
keyword_replacements:
  class: klass
plugins:
  - plugins/plugin.dart
''');

    final config = await Config.load(configFile);

    expect(config.outputDir, 'generated_out');
    expect(config.inputDir, inputDir.path);
    expect(config.schemaPath, schemaPath);
    expect(config.nullableMode, NullableMode.optional);
    expect(config.compressQueries, isFalse);
    expect(config.emitHelpers, isTrue);
    expect(config.namePrefix, 'Foo');
    expect(config.logLevel, LogLevel.warning);

    final scalar = config.scalarMapping;
    expect(scalar['DateTime']?.symbol, 'CustomDateTime');
    expect(scalar['DateTime']?.import, isNull);
    expect(scalar['Money']?.symbol, 'MoneyType');
    expect(scalar['Money']?.import, 'package:money/money.dart');

    expect(config.keywordReplacements['class'], 'klass');
    expect(config.pluginPaths, [pluginPath]);
  });
}
