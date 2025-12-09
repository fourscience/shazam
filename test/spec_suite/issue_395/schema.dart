// Generated schema types
typedef GqlCarInput = ({
  String idNonNullable,
  String? idNullable,
});
GqlCarInput deserializeGqlCarInput(Map<String, dynamic> json) {
  return (
    idNonNullable: json['idNonNullable'] as String,
    idNullable: json['idNullable'] as String?,
  );
}

Map<String, dynamic> serializeGqlCarInput(GqlCarInput data) {
  return {
    'idNonNullable': data.idNonNullable,
    'idNullable': data.idNullable,
  };
}
