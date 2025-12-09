import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/shazam.dart';
import 'package:test/test.dart';

void main() {
  test('custom scalars map to consumer types with imports and serializers',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('shazam_scalar_');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    const schema = '''
scalar DateTime

type Query {
  now: DateTime!
  events: [DateTime]
}

type Mutation {
  setTime(at: DateTime!): DateTime!
}
''';

    const operations = r'''
query GetTimes {
  now
  events
}

mutation SetTime($at: DateTime!) {
  setTime(at: $at)
}
''';

    final schemaPath = p.join(tempDir.path, 'schema.graphql');
    final opsPath = p.join(tempDir.path, 'ops.graphql');
    await File(schemaPath).writeAsString(schema);
    await File(opsPath).writeAsString(operations);

    final outputDir = p.join(tempDir.path, 'generated');
    final config = Config(
      outputDir: outputDir,
      inputDir: tempDir.path,
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: true,
      schemaPath: schemaPath,
      scalarMapping: const {
        'DateTime': ScalarConfig(
          symbol: 'CustomDateTime',
          import: 'package:custom/scalars.dart',
        ),
      },
      configPath: 'config.yaml',
      keywordReplacements: const {},
      pluginPaths: const [],
    );

    final generator = Generator(config);
    await generator.build();

    final getTimesSource =
        File(p.join(outputDir, 'operations', 'GetTimes.dart'))
            .readAsStringSync();
    expect(getTimesSource, contains("import 'package:custom/scalars.dart';"));
    expect(
      getTimesSource,
      contains(
          "CustomDateTime.deserialize(json['now'] as String)"), // scalar deserialize
    );
    expect(
      getTimesSource,
      contains(
          'map((e) => e == null ? null : CustomDateTime.deserialize(e as String))'),
    );

    final setTimeSource = File(p.join(outputDir, 'operations', 'SetTime.dart'))
        .readAsStringSync();
    expect(setTimeSource, contains("import 'package:custom/scalars.dart';"));
    expect(
      setTimeSource,
      contains(
          "setTime: CustomDateTime.deserialize(json['setTime'] as String)"),
    );
    expect(
      setTimeSource,
      contains("'at': data.at.serialize(),"), // variable serializer
    );
  });
}
