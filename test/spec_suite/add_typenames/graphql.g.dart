import 'dart:convert';
import 'dart:io' show gzip;
import '__generated__/Q.dart';

// Generated helpers
String decompress(String input) =>
    utf8.decode(gzip.decode(base64Decode(input)));
const _interfaceImpls = <String, Set<String>>{
  'Document': {'Contract', 'Report'},
};

const _unionVariants = <String, Set<String>>{};

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

typedef ResponseParser<T> = T Function(Map<String, dynamic>);
final responseParsers = <String, dynamic Function(Map<String, dynamic>)>{
  'GqlQ': parseGqlQResponse,
};
dynamic Function(Map<String, dynamic>)? resolveParser(String key) =>
    responseParsers[key];
