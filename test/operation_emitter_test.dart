import 'dart:convert';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/emitters/operation_emitter.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:test/test.dart';

Config _config({bool compressQueries = false}) => Config(
      outputDir: 'out',
      inputDir: 'lib',
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: compressQueries,
      emitHelpers: false,
      schemaPath: 'schema.graphql',
      scalarMapping: const {},
      configPath: 'config.yaml',
      keywordReplacements: const {},
      pluginPaths: const [],
      logLevel: LogLevel.info,
    );

OperationDefinitionNode _op(String source) =>
    parseString(source).definitions.whereType<OperationDefinitionNode>().first;

void main() {
  group('OperationEmitter', () {
    test('builds operation const with injected name', () {
      final emitter = OperationEmitter(_config(), const TypeHelper());
      final node = _op('query Fetch { __typename }');

      final result = emitter.operationConst('Fetch', node);

      expect(result, contains("const GqlFetchOperation = r'''"));
      expect(result, contains('query Fetch'));
    });

    test('compresses queries and exposes getter', () {
      final emitter =
          OperationEmitter(_config(compressQueries: true), const TypeHelper());
      final node = _op('mutation DoThing { __typename }');

      final result = emitter.operationConst('DoThing', node);

      expect(result, contains('GqlDoThingOperationCompressed'));
      expect(result, contains('String get GqlDoThingOperation'));
      final encoded = RegExp("= '([^']+)';").firstMatch(result)!.group(1)!;
      expect(base64Decode(encoded), isNotEmpty);
    });

    test('builds request map without typed variables', () {
      final emitter = OperationEmitter(_config(), const TypeHelper());
      final request = emitter.operationRequest(
        'Fetch',
        null,
        const {'foo': 1},
      );

      expect(request, contains("'query': GqlFetchOperation"));
      expect(request, contains("'variables': _vars"));
      expect(request, contains('"foo":1'));
      expect(request, isNot(contains('serialize')));
    });

    test('builds request map with typed variables', () {
      final emitter = OperationEmitter(_config(), const TypeHelper());
      final request = emitter.operationRequest(
        'Fetch',
        'FetchVariables',
        const {'foo': 'bar'},
      );

      expect(request, contains('serializeFetchVariables'));
      expect(request, contains('GqlFetchOperation'));
      expect(request, contains('"foo":"bar"'));
    });

    test('builds fragment const with prefix', () {
      final emitter = OperationEmitter(_config(), const TypeHelper());
      final frag = parseString('fragment Thing on Query { __typename }')
          .definitions
          .whereType<FragmentDefinitionNode>()
          .first;

      final result = emitter.fragmentConst('Thing', frag);

      expect(result, contains('const GqlThingFragment'));
      expect(result, contains('__typename'));
    });
  });
}
