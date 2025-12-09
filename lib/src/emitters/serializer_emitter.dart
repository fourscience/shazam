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
    final nullable = type.endsWith('?');
    final core = nullable ? type.substring(0, type.length - 1) : type;

    if (typeHelper.isThunk(type)) {
      final inner = thunkTarget ?? typeHelper.unwrapThunk(type);
      final deser = deserializeForType(inner, source, recordNames, enumNames);
      return nullable
          ? '$source == null ? null : () => $deser'
          : '() => $deser';
    }

    if (core.startsWith('List<') && core.endsWith('>')) {
      final inner = core.substring(5, core.length - 1);
      final src = nullable ? '($source as List?)' : '($source as List)';
      final chain = nullable ? '?.' : '.';
      final innerExpr = deserializeForType(inner, 'e', recordNames, enumNames);
      return "$src$chain" "map((e) => $innerExpr).toList()";
    }

    if (recordNames.contains(core)) {
      final deser = 'deserialize$core($source as Map<String, dynamic>)';
      return nullable ? '$source == null ? null : $deser' : deser;
    }

    if (enumNames.contains(core)) {
      final cast = '$source as String';
      final deser = '$core.values.byName($cast)';
      return nullable ? '$source == null ? null : $deser' : deser;
    }

    final scalar = scalarTypes[core];
    if (scalar != null) {
      final deser = '${scalar.symbol}.deserialize($source as String)';
      return nullable ? '$source == null ? null : $deser' : deser;
    }

    return '$source as ${nullable ? '$core?' : core}';
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
      return nullable ? '$source?.serialize()' : '$source.serialize()';
    }

    return source;
  }
}
