import '../config.dart';
import '../name_type_helpers.dart';

class SerializerEmitter {
  SerializerEmitter(this.typeHelper, this.scalarTypes);

  final TypeHelper typeHelper;
  final Map<String, ScalarConfig> scalarTypes;

  String deserializeForType(
    String type,
    String source,
    Set<String> recordNames,
    Set<String> enumNames, {
    String? thunkTarget,
  }) {
    bool _needsWrap(String value) =>
        value.contains('??') || value.contains('&&') || value.contains('||');
    String _wrap(String value) => _needsWrap(value) ? '($value)' : value;
    bool _isSimpleAccess(String value) => RegExp(
            r"^([A-Za-z_][A-Za-z0-9_]*|json\['[^']+'\])$")
        .hasMatch(value);
    final safeSource = _wrap(source);
    final nullable = type.endsWith('?');
    final core = nullable ? type.substring(0, type.length - 1) : type;

    if (typeHelper.isThunk(type)) {
      final inner = thunkTarget ?? typeHelper.unwrapThunk(type);
      final deser =
          deserializeForType(inner, safeSource, recordNames, enumNames);
      return nullable
          ? '$safeSource == null ? null : () => $deser'
          : '() => $deser';
    }

    if (core.startsWith('List<') && core.endsWith('>')) {
      final inner = core.substring(5, core.length - 1);
      final src = nullable
          ? '($safeSource as List?)'
          : '($safeSource as List)';
      final chain = nullable ? '?.' : '.';
      final innerExpr = deserializeForType(inner, 'e', recordNames, enumNames);
      return "$src$chain" "map((e) => $innerExpr).toList()";
    }

    if (recordNames.contains(core)) {
      final deser =
          'deserialize$core($safeSource as Map<String, dynamic>)';
      return nullable ? '$safeSource == null ? null : $deser' : deser;
    }

    if (enumNames.contains(core)) {
      final cast = '$safeSource as String';
      final deser = '$core.values.byName($cast)';
      return nullable ? '$safeSource == null ? null : $deser' : deser;
    }

    final scalar = scalarTypes[core];
    if (scalar != null) {
      if (!_requiresSerializer(scalar.symbol, scalar.hasImport)) {
        return '$safeSource as ${nullable ? '${scalar.symbol}?' : scalar.symbol}';
      }
      final castSource = _isSimpleAccess(source) ? source : safeSource;
      final deser = '${scalar.symbol}.deserialize($castSource as String)';
      return nullable ? '$safeSource == null ? null : $deser' : deser;
    }

    return '$safeSource as ${nullable ? '$core?' : core}';
  }

  String serializeForType(
    String type,
    String source,
    Set<String> recordNames,
    Set<String> enumNames, {
    String? thunkTarget,
  }) {
    final nullable = type.endsWith('?');
    final core = nullable ? type.substring(0, type.length - 1) : type;

    if (typeHelper.isThunk(type)) {
      final inner = thunkTarget ?? typeHelper.unwrapThunk(type);
      final invoked = nullable ? '$source?.call()' : '$source()';
      return serializeForType(inner, invoked, recordNames, enumNames);
    }

    if (core.startsWith('List<') && core.endsWith('>')) {
      final inner = core.substring(5, core.length - 1);
      final chain = nullable ? '?.' : '.';
      final innerExpr = serializeForType(inner, 'e', recordNames, enumNames);
      return "$source$chain" "map((e) => $innerExpr).toList()";
    }

    if (recordNames.contains(core)) {
      final nonNullSource =
          nullable ? '($source! as $core)' : '($source as $core)';
      final ser = 'serialize$core($nonNullSource)';
      return nullable ? '$source == null ? null : $ser' : ser;
    }

    if (enumNames.contains(core)) {
      return nullable ? '$source?.name' : '$source.name';
    }

    final scalar = scalarTypes[core];
    if (scalar != null) {
      if (!_requiresSerializer(scalar.symbol, scalar.hasImport)) {
        return source;
      }
      return nullable ? '$source?.serialize()' : '$source.serialize()';
    }

    return source;
  }

  bool _requiresSerializer(String symbol, bool hasImport) {
    const primitives = {
      'String',
      'int',
      'double',
      'num',
      'bool',
      'dynamic',
      'Object'
    };
    if (!hasImport && primitives.contains(symbol)) return false;
    return true;
  }
}
