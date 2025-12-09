// Generated schema types
enum GqlLocale { daDk, nbNo }

typedef GqlIInput = ({
  String? s,
});
GqlIInput deserializeGqlIInput(Map<String, dynamic> json) {
  return (s: json['s'] as String?,);
}

Map<String, dynamic> serializeGqlIInput(GqlIInput data) {
  return {
    's': data.s,
  };
}
