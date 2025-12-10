import 'package:shazam/src/config.dart';
import 'package:shazam/src/naming_helper.dart';
import 'package:test/test.dart';

Config _config({Map<String, String> keywordReplacements = const {}}) => Config(
      outputDir: 'out',
      inputDir: 'lib',
      nullableMode: NullableMode.required,
      namePrefix: 'Gql',
      compressQueries: false,
      emitHelpers: false,
      schemaPath: 'schema.graphql',
      scalarMapping: const {},
      configPath: 'config.yaml',
      keywordReplacements: keywordReplacements,
      pluginPaths: const [],
      logLevel: LogLevel.info,
    );

void main() {
  group('NamingHelper', () {
    test('formats strings to pascal and camel case', () {
      final helper = NamingHelper(_config());
      expect(helper.pascal('my_field'), 'MyField');
      expect(helper.camel('MyField'), 'myField');
      expect(helper.pascal(''), isEmpty);
      expect(helper.camel(''), isEmpty);
    });

    test('sanitizes identifiers using config keyword replacements', () {
      final helper =
          NamingHelper(_config(keywordReplacements: {'class': 'klass'}));
      expect(helper.sanitize('class'), 'klass');

      final fallback = NamingHelper(_config());
      expect(fallback.sanitize('class'), 'rClass');
    });
  });

  group('TypeHelper', () {
    const helper = TypeHelper();

    test('extracts core types', () {
      expect(helper.coreType('List<String?>'), 'String');
      expect(helper.coreType('List<List<int?>>'), 'int');
      expect(helper.coreType('Thunk Function()'), 'Thunk');
      expect(helper.coreType('Thunk? Function()?'), 'Thunk?');
    });

    test('handles list helpers', () {
      expect(helper.isList('List<int>'), isTrue);
      expect(helper.unwrapList('List<int?>'), 'int?');
      expect(helper.wrapList('String'), 'List<String>');
      expect(helper.wrapList('String', nullable: true), 'List<String>?');
    });

    test('handles nullability helpers', () {
      expect(helper.isNullable('int?'), isTrue);
      expect(helper.withoutNullability('int?'), 'int');
      expect(helper.asNullable('int'), 'int?');
    });

    test('handles thunk helpers', () {
      expect(helper.isThunk('Widget Function()'), isTrue);
      expect(helper.isThunk('Widget Function()?'), isTrue);
      expect(helper.unwrapThunk('Widget Function()?'), 'Widget?');
      expect(helper.unwrapThunk('Widget Function()'), 'Widget');
      expect(helper.wrapThunk('Widget'), 'Widget Function()');
      expect(helper.wrapThunk('Widget?'), 'Widget? Function()?');
    });
  });
}
