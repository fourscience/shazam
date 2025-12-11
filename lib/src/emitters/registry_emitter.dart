import 'package:code_builder/code_builder.dart';
import 'package:shazam/src/config.dart';
import 'package:shazam/src/emitters/emitter.dart';
import 'package:shazam/src/ir/ir.dart';

/// Emits the shared helper library used by generated operation files.
class RegistryEmitter implements Emitter<Library> {
  RegistryEmitter(this.config);

  final Config config;

  @override
  Library emit() => Library((b) => b..body.add(const Code('// registry')));

  /// Builds a helper library that contains decompress utilities, type helpers,
  /// and the registry of operation parsers.
  Library emitHelpers(DocumentIr ir, Iterable<String> operationImports) {
    final builder = LibraryBuilder()
      ..directives.addAll([
        Directive.import('dart:convert'),
        Directive.import('dart:io', show: const ['gzip']),
        ...operationImports.map(Directive.import),
      ])
      ..body.add(const Code('\n// Generated helpers\n'))
      ..body.add(const Code(
          'String decompress(String input) => utf8.decode(gzip.decode(base64Decode(input)));'))
      ..body.add(Code(_typeHelpers(ir)))
      ..body.add(Code(_serializerRegistry(ir)));
    return builder.build();
  }

  String _typeHelpers(DocumentIr ir) {
    final interfaceMap = _emitTypeMap(ir.interfaceImplementations);
    final unionMap = _emitTypeMap(ir.unionVariants);
    return '''
const _interfaceImpls = <String, Set<String>>{
$interfaceMap};

const _unionVariants = <String, Set<String>>{
$unionMap};

bool isTypeName(dynamic record, String expected) {
  final typeName = (record as dynamic).typeName;
  return typeName == expected;
}

/// Checks if a record matches a concrete type, interface, or union name.
bool isTypeOf(dynamic record, String target) {
  final typeName = (record as dynamic).typeName;
  if (typeName == target) return true;
  final impls = _interfaceImpls[target];
  if (impls != null && impls.contains(typeName)) return true;
  final variants = _unionVariants[target];
  if (variants != null && variants.contains(typeName)) return true;
  return false;
}
''';
  }

  String _serializerRegistry(DocumentIr ir) {
    final buffer = StringBuffer()
      ..writeln('typedef ResponseParser<T> = T Function(Map<String, dynamic>);')
      ..writeln(
          'final responseParsers = <String, dynamic Function(Map<String, dynamic>)>{');
    for (final op in ir.operations) {
      final key = '${config.namePrefix}${op.name}';
      final parseName = 'parse${config.namePrefix}${op.name}Response';
      buffer.writeln("  '$key': $parseName,");
    }
    buffer.writeln('};');

    buffer.writeln(
        'dynamic Function(Map<String, dynamic>)? resolveParser(String key) => responseParsers[key];');
    return buffer.toString();
  }

  String _emitTypeMap(Map<String, Set<String>> map) {
    final buffer = StringBuffer();
    for (final entry in map.entries) {
      final values = entry.value.map((e) => "'$e'").join(', ');
      buffer.writeln("  '${entry.key}': {$values},");
    }
    return buffer.toString();
  }
}
