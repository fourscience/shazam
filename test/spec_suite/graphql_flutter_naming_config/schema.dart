// Generated schema types
enum GqlStatus { pending, succeFul, failure, inprogre }

typedef GqlInput = ({
  GqlStatus? status,
});
GqlInput deserializeGqlInput(Map<String, dynamic> json) {
  return (
    status: json['status'] == null
        ? null
        : GqlStatus.values.byName(json['status'] as String),
  );
}

Map<String, dynamic> serializeGqlInput(GqlInput data) {
  return {
    'status': data.status?.name,
  };
}
