// Generated schema types
typedef GqlI1Input = ({
  int? v1,
  int? v2,
  int? v3,
});
GqlI1Input deserializeGqlI1Input(Map<String, dynamic> json) {
  return (
    v1: json['v1'] as int?,
    v2: json['v2'] as int?,
    v3: json['v3'] as int?,
  );
}

Map<String, dynamic> serializeGqlI1Input(GqlI1Input data) {
  return {
    'v1': data.v1,
    'v2': data.v2,
    'v3': data.v3,
  };
}

typedef GqlI2Input = ({
  int? v1,
  int? v2,
  int v3,
});
GqlI2Input deserializeGqlI2Input(Map<String, dynamic> json) {
  return (
    v1: json['v1'] as int?,
    v2: json['v2'] as int?,
    v3: json['v3'] as int,
  );
}

Map<String, dynamic> serializeGqlI2Input(GqlI2Input data) {
  return {
    'v1': data.v1,
    'v2': data.v2,
    'v3': data.v3,
  };
}
