// Generated schema types
enum GqlE { FOO }

typedef GqlInInput = ({
  String? string,
});
GqlInInput deserializeGqlInInput(Map<String, dynamic> json) {
  return (string: json['string'] as String?,);
}

Map<String, dynamic> serializeGqlInInput(GqlInInput data) {
  return {
    'string': data.string,
  };
}
