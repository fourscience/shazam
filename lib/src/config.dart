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

  static Future<Config> load(File file) async {
    if (!file.existsSync()) {
      return Config._default();
    }
    final content = await file.readAsString();
    final doc = loadYaml(content) as YamlMap;
    final scalarSection = (doc['scalars'] as YamlMap?) ?? YamlMap();
    final scalars = <String, ScalarConfig>{};
    for (final entry in scalarSection.entries) {
      if (entry.value is String) {
        scalars[entry.key as String] =
            ScalarConfig.inline(entry.value as String);
      } else if (entry.value is YamlMap) {
        final map = entry.value as YamlMap;
        scalars[entry.key as String] = ScalarConfig.imported(
          name: map['name'] as String,
          path: map['path'] as String,
        );
      }
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
      if (value.isImported) {
        if ((value.name ?? '').isEmpty || (value.path ?? '').isEmpty) {
          issues
              .add('scalar "$key" imported mapping must include name and path');
        }
      } else if ((value.target ?? '').isEmpty) {
        issues.add('scalar "$key" inline mapping must be non-empty');
      }
    }

    if (issues.isNotEmpty) {
      throw StateError('Config validation failed:\n- ${issues.join('\n- ')}');
    }
  }
}

enum NullableMode { required, optional }

class ScalarConfig {
  ScalarConfig.inline(this.target)
      : name = null,
        path = null;
  ScalarConfig.imported({required this.name, required this.path})
      : target = null;

  final String? target; // simple mapping
  final String? name;
  final String? path;

  bool get isInline => target != null;
  bool get isImported => name != null && path != null;
}
