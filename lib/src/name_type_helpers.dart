import 'package:change_case/change_case.dart';

import 'config.dart';

/// Shared naming utilities backed by [Config.sanitizeIdentifier].
class NamingHelper {
  NamingHelper(this.config);

  final Config config;

  String pascal(String value) {
    if (value.isEmpty) return value;
    return value.toPascalCase();
  }

  String camel(String value) {
    if (value.isEmpty) return value;
    return value.toCamelCase();
  }

  String sanitize(String name) => config.sanitizeIdentifier(name);
}

/// Shared type helpers for list/nullability/thunk handling.
class TypeHelper {
  const TypeHelper();

  String coreType(String type) {
    var current = type;
    if (current.endsWith('?')) {
      current = current.substring(0, current.length - 1);
    }
    if (isThunk(current)) {
      current = unwrapThunk(current);
    }
    while (current.startsWith('List<') && current.endsWith('>')) {
      current = current.substring(5, current.length - 1);
      if (current.endsWith('?')) {
        current = current.substring(0, current.length - 1);
      }
    }
    return current;
  }

  bool isList(String type) {
    final t = withoutNullability(type);
    return t.startsWith('List<') && t.endsWith('>');
  }

  String unwrapList(String type) {
    final t = withoutNullability(type);
    if (t.startsWith('List<') && t.endsWith('>')) {
      return t.substring(5, t.length - 1);
    }
    return type;
  }

  String wrapList(String type, {bool nullable = false}) {
    final base = 'List<$type>';
    return nullable ? '$base?' : base;
  }

  bool isNullable(String type) => type.endsWith('?');

  String withoutNullability(String type) =>
      isNullable(type) ? type.substring(0, type.length - 1) : type;

  String asNullable(String type) => isNullable(type) ? type : '$type?';

  bool isThunk(String type) =>
      type.endsWith(' Function()') || type.endsWith(' Function()?');

  String unwrapThunk(String type) {
    if (type.endsWith(' Function()?')) {
      return '${type.substring(0, type.length - ' Function()?'.length)}?';
    }
    if (type.endsWith(' Function()')) {
      return type.substring(0, type.length - ' Function()'.length);
    }
    return type;
  }

  String wrapThunk(String type) {
    final nullable = isNullable(type);
    return nullable ? '$type Function()?' : '$type Function()';
  }
}
