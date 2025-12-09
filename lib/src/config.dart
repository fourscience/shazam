import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class Config {
  Config({
    required this.outputDir,
    required this.inputDir,
    required this.nullableMode,
    required this.namePrefix,
    required this.compressQueries,
    required this.emitHelpers,
    required this.schemaPath,
    required this.scalarMapping,
    required this.configPath,
    required this.keywordReplacements,
  });

  final String outputDir;
  final String inputDir;
  final String schemaPath;
  final String configPath;
  final NullableMode nullableMode;
  final String namePrefix;
  final bool compressQueries;
  final bool emitHelpers;
  final Map<String, ScalarConfig> scalarMapping;
  final Map<String, String> keywordReplacements;

  static Future<Config> load(File file) async {
    if (!file.existsSync()) {
      return Config._default();
    }
    final content = await file.readAsString();
    final doc = loadYaml(content) as YamlMap;
    final scalarSection = (doc['scalars'] as YamlMap?) ?? YamlMap();
    final scalars = <String, ScalarConfig>{};
    for (final entry in scalarSection.entries) {
      scalars[entry.key as String] =
          ScalarConfig.fromYaml(entry.value, key: entry.key as String);
    }
    final keywordReplacements = <String, String>{};
    final keywordSection =
        (doc['keyword_replacements'] as YamlMap?) ?? YamlMap();
    for (final entry in keywordSection.entries) {
      keywordReplacements[entry.key as String] = entry.value as String;
    }

    final nullableMode = _parseNullableMode(doc['nullable_mode'] as String?);

    final schemaPath = doc['schema'] as String? ?? 'schema.graphql';
    final configDir = p.dirname(file.path);

    final cfg = Config(
      outputDir: doc['output_dir'] as String? ?? 'generated',
      inputDir: doc['input_dir'] as String? ?? 'lib',
      nullableMode: nullableMode,
      namePrefix: doc['name_prefix'] as String? ?? 'Gql',
      compressQueries: (doc['compress_queries'] as bool?) ?? true,
      emitHelpers: (doc['emit_helpers'] as bool?) ?? true,
      schemaPath: p.normalize(p.join(configDir, schemaPath)),
      scalarMapping: scalars,
      configPath: file.path,
      keywordReplacements: keywordReplacements,
    );
    cfg._validate();
    return cfg;
  }

  static NullableMode _parseNullableMode(String? value) {
    switch (value) {
      case 'optional':
        return NullableMode.optional;
      case 'required':
      default:
        return NullableMode.required;
    }
  }

  factory Config._default() => Config(
        outputDir: 'generated',
        inputDir: 'lib',
        nullableMode: NullableMode.required,
        namePrefix: 'Gql',
        compressQueries: true,
        emitHelpers: true,
        schemaPath: 'schema.graphql',
        scalarMapping: {},
        configPath: 'config.yaml',
        keywordReplacements: const {},
      );

  void _validate() {
    final issues = <String>[];

    if (!File(schemaPath).existsSync()) {
      issues.add('schema not found at $schemaPath');
    }
    if (!Directory(inputDir).existsSync()) {
      issues.add('input_dir not found at $inputDir');
    }
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(namePrefix)) {
      issues.add(
          'name_prefix "$namePrefix" is invalid (must be a valid Dart identifier prefix)');
    }

    final scalarKeys = <String>{};
    for (final entry in scalarMapping.entries) {
      final key = entry.key;
      if (!scalarKeys.add(key)) {
        issues.add('duplicate scalar mapping for "$key"');
      }
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
        issues
            .add('scalar key "$key" is invalid (must be a GraphQL identifier)');
      }
      final value = entry.value;
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value.symbol)) {
        issues.add(
            'scalar "$key" symbol "${value.symbol}" is invalid (must be a Dart identifier)');
      }
      if (value.import != null && (value.import!.trim().isEmpty)) {
        issues.add('scalar "$key" import must be non-empty when provided');
      }
    }

    if (issues.isNotEmpty) {
      throw StateError('Config validation failed:\n- ${issues.join('\n- ')}');
    }
  }

  static const _dartKeywords = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  String sanitizeIdentifier(String name) {
    final replacement = keywordReplacements[name];
    if (replacement != null && replacement.isNotEmpty) return replacement;
    if (_dartKeywords.contains(name)) {
      if (name.isEmpty) return 'r';
      final pascal = name[0].toUpperCase() + name.substring(1);
      return 'r$pascal';
    }
    return name;
  }
}

enum NullableMode { required, optional }

class ScalarConfig {
  const ScalarConfig({required this.symbol, this.import});

  factory ScalarConfig.fromYaml(dynamic value, {required String key}) {
    if (value is String) {
      return ScalarConfig(symbol: value);
    }
    if (value is YamlMap) {
      final map = value;
      final symbol = map['symbol'] as String?;
      final import = (map['import'] ?? map['path']) as String?;
      return ScalarConfig(symbol: symbol ?? '', import: import);
    }
    throw StateError('scalar "$key" must map to a string or map');
  }

  final String symbol;
  final String? import;

  bool get hasImport => import != null && import!.isNotEmpty;
}
