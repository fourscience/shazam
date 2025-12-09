// Generated schema types
typedef GqlIInput = ({
  String? title,
});
GqlIInput deserializeGqlIInput(Map<String, dynamic> json) {
  return (title: json['title'] as String?,);
}

Map<String, dynamic> serializeGqlIInput(GqlIInput data) {
  return {
    'title': data.title,
  };
}
