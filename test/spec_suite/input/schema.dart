// Generated schema types
enum GqlE { FOO, BAR, BAZ }

class GqlI1Input {
  const GqlI1Input({
    this._min,
    this.children,
    this.children2,
    this.e,
    this.eMaybe,
    this.es,
    this.i2,
    this.nested_input,
    this.s,
    this.sMaybe,
  });
  final int? _min;
  final List<GqlI1Input>? Function()? children;
  final List<List<GqlI1Input?>?>? Function()? children2;
  final GqlE e;
  final GqlE? eMaybe;
  final List<GqlE> es;
  final GqlI2Input? i2;
  final GqlI1Input? Function()? nested_input;
  final String s;
  final String? sMaybe;
}

GqlI1Input deserializeGqlI1Input(Map<String, dynamic> json) {
  return GqlI1Input(
    _min: json['_min'] as int?,
    children: json['children'] == null
        ? null
        : () => (json['children'] as List?)
            ?.map((e) => deserializeGqlI1Input(e as Map<String, dynamic>))
            .toList(),
    children2: json['children2'] == null
        ? null
        : () => (json['children2'] as List?)
            ?.map((e) => (e as List?)
                ?.map((e) => e == null
                    ? null
                    : deserializeGqlI1Input(e as Map<String, dynamic>))
                .toList())
            .toList(),
    e: GqlE.values.byName(json['e'] as String),
    eMaybe: json['eMaybe'] == null
        ? null
        : GqlE.values.byName(json['eMaybe'] as String),
    es: (json['es'] as List)
        .map((e) => GqlE.values.byName(e as String))
        .toList(),
    i2: json['i2'] == null
        ? null
        : deserializeGqlI2Input(json['i2'] as Map<String, dynamic>),
    nested_input: json['nested_input'] == null
        ? null
        : () => json['nested_input'] == null
            ? null
            : deserializeGqlI1Input(
                json['nested_input'] as Map<String, dynamic>),
    s: json['s'] as String,
    sMaybe: json['sMaybe'] as String?,
  );
}

Map<String, dynamic> serializeGqlI1Input(GqlI1Input data) {
  final _result = <String, dynamic>{
    '_min': data._min,
    'e': data.e.name,
    'eMaybe': data.eMaybe?.name,
    'es': data.es.map((e) => e.name).toList(),
    'i2':
        data.i2 == null ? null : serializeGqlI2Input((data.i2! as GqlI2Input)),
    's': data.s,
    'sMaybe': data.sMaybe,
  };
  final _childrenValue = data.children?.call();
  if (_childrenValue != null) {
    _result['children'] = _childrenValue
        ?.map((e) => serializeGqlI1Input((e as GqlI1Input)))
        .toList();
  }
  final _children2Value = data.children2?.call();
  if (_children2Value != null) {
    _result['children2'] = _children2Value
        ?.map((e) => e
            ?.map((e) =>
                e == null ? null : serializeGqlI1Input((e! as GqlI1Input)))
            .toList())
        .toList();
  }
  final _nested_inputValue = data.nested_input?.call();
  if (_nested_inputValue != null) {
    _result['nested_input'] = _nested_inputValue == null
        ? null
        : serializeGqlI1Input((_nested_inputValue! as GqlI1Input));
  }
  return _result;
}

typedef GqlI2Input = ({
  String? foobar,
});
GqlI2Input deserializeGqlI2Input(Map<String, dynamic> json) {
  return (foobar: json['foobar'] as String?,);
}

Map<String, dynamic> serializeGqlI2Input(GqlI2Input data) {
  return {
    'foobar': data.foobar,
  };
}
