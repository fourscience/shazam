// Generated schema types
typedef GqlInput = ({
  bool? inputField,
});
GqlInput deserializeGqlInput(Map<String, dynamic> json) {
  return (inputField: json['inputField'] as bool?,);
}

Map<String, dynamic> serializeGqlInput(GqlInput data) {
  return {
    'inputField': data.inputField,
  };
}
