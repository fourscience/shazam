// Generated schema types
enum GqlReaction { LIKE, LOVE, WOW, ANGRY, SAD }

enum GqlRole { USER, ADMIN, MODERATOR }

class GqlMetadataInput {
  const GqlMetadataInput({
    this.isPublished,
    this.not,
    this.rIn,
    this.rating,
  });
  final bool? isPublished;
  final GqlMetadataInput? Function()? not;
  final List<GqlMetadataInput?>? Function()? rIn;
  final double? rating;
}

GqlMetadataInput deserializeGqlMetadataInput(Map<String, dynamic> json) {
  return GqlMetadataInput(
    isPublished: json['isPublished'] as bool?,
    not: json['not'] == null
        ? null
        : () => json['not'] == null
            ? null
            : deserializeGqlMetadataInput(json['not'] as Map<String, dynamic>),
    rIn: json['in'] == null
        ? null
        : () => (json['in'] as List?)
            ?.map((e) => e == null
                ? null
                : deserializeGqlMetadataInput(e as Map<String, dynamic>))
            .toList(),
    rating: json['rating'] as double?,
  );
}

Map<String, dynamic> serializeGqlMetadataInput(GqlMetadataInput data) {
  final _result = <String, dynamic>{
    'isPublished': data.isPublished,
    'rating': data.rating,
  };
  final _notValue = data.not?.call();
  if (_notValue != null) {
    _result['not'] = _notValue == null
        ? null
        : serializeGqlMetadataInput((_notValue! as GqlMetadataInput));
  }
  final _rInValue = data.rIn?.call();
  if (_rInValue != null) {
    _result['in'] = _rInValue
        ?.map((e) => e == null
            ? null
            : serializeGqlMetadataInput((e! as GqlMetadataInput)))
        .toList();
  }
  return _result;
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
        : serializeGqlMetadataInput((data.metadata! as GqlMetadataInput)),
    'tags': data.tags?.map((e) => e).toList(),
    'title': data.title,
  };
}
