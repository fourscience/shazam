// Generated schema types
typedef GqlInput = ({
  String? field,
  bool? flag,
});
GqlInput deserializeGqlInput(Map<String, dynamic> json) {
  return (
    field: json['field'] as String?,
    flag: json['flag'] as bool?,
  );
}

Map<String, dynamic> serializeGqlInput(GqlInput data) {
  return {
    'field': data.field,
    'flag': data.flag,
  };
}
