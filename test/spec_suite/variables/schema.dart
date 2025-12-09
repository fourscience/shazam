// Generated schema types
class GqlI1Input {
  const GqlI1Input({
    this.nested,
    this.s,
  });
  final GqlI1Input? Function()? nested;
  final String s;
}

GqlI1Input deserializeGqlI1Input(Map<String, dynamic> json) {
  return GqlI1Input(
    nested: json['nested'] == null
        ? null
        : () => json['nested'] == null
            ? null
            : deserializeGqlI1Input(json['nested'] as Map<String, dynamic>),
    s: json['s'] as String,
  );
}

Map<String, dynamic> serializeGqlI1Input(GqlI1Input data) {
  final _result = <String, dynamic>{
    's': data.s,
  };
  final _nestedValue = data.nested?.call();
  if (_nestedValue != null) {
    _result['nested'] = _nestedValue == null
        ? null
        : serializeGqlI1Input((_nestedValue! as GqlI1Input));
  }
  return _result;
}
