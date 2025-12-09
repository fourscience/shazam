// Generated schema types
typedef GqlIInput = ({
  int? OtherReservedKeyword,
  String? String,
});
GqlIInput deserializeGqlIInput(Map<String, dynamic> json) {
  return (
    OtherReservedKeyword: json['OtherReservedKeyword'] as int?,
    String: json['String'] as String?,
  );
}

Map<String, dynamic> serializeGqlIInput(GqlIInput data) {
  return {
    'OtherReservedKeyword': data.OtherReservedKeyword,
    'String': data.String,
  };
}
