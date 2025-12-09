// Generated types
enum GqlReaction { LIKE, LOVE, WOW, ANGRY, SAD }

enum GqlRole { USER, ADMIN, MODERATOR }

typedef GqlMetadataInput = ({
  bool? isPublished,
  double? rating,
});
GqlMetadataInput deserializeGqlMetadataInput(Map<String, dynamic> json) {
  return (
    isPublished: json['isPublished'] as bool?,
    rating: json['rating'] as double?,
  );
}

Map<String, dynamic> serializeGqlMetadataInput(GqlMetadataInput data) {
  return {
    'isPublished': data.isPublished,
    'rating': data.rating,
  };
}

typedef GqlPostInput = ({
  String? content,
  GqlMetadataInput? metadata,
  List<String>? tags,
  String title,
});
GqlPostInput deserializeGqlPostInput(Map<String, dynamic> json) {
  return (
    content: json['content'] as String?,
    metadata: json['metadata'] == null
        ? null
        : deserializeGqlMetadataInput(json['metadata'] as Map<String, dynamic>),
    tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
    title: json['title'] as String,
  );
}

Map<String, dynamic> serializeGqlPostInput(GqlPostInput data) {
  return {
    'content': data.content,
    'metadata': data.metadata == null
        ? null
        : serializeGqlMetadataInput(data.metadata!),
    'tags': data.tags?.map((e) => e).toList(),
    'title': data.title,
  };
}
