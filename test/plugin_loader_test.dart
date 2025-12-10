import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';
import 'package:shazam/src/plugin_loader.dart';
import 'package:test/test.dart';

void main() {
  test('PluginLoader reads plugin exports in all supported shapes', () async {
    final fixturesDir =
        p.join(Directory.current.path, 'test', 'fixtures', 'plugins');
    final config = Config(
      outputDir: 'out',
      inputDir: 'lib',
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: false,
      schemaPath: 'schema.graphql',
      scalarMapping: const {},
      configPath: 'config.yaml',
      keywordReplacements: const {},
      pluginPaths: [
        p.join(fixturesDir, 'single_plugin.dart'),
        p.join(fixturesDir, 'list_plugin.dart'),
        p.join(fixturesDir, 'factory_plugin.dart'),
      ],
      logLevel: LogLevel.info,
    );

    const loader = PluginLoader();
    final plugins = await loader.load(config);

    final typeNames =
        plugins.map((p) => p.plugin.runtimeType.toString()).toList();
    expect(
      typeNames,
      containsAll(['SinglePlugin', 'ListPlugin', 'FactoryPlugin']),
    );
    expect(plugins, hasLength(4)); // 1 + 2 + 1 plugins loaded
  });
}
