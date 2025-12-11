import 'package:meta/meta.dart'; // Generated schema types

enum GqlReaction { LIKE, LOVE, WOW, ANGRY, SAD }

enum GqlRole {
  USER,
  ADMIN,
  @Deprecated('No more moderation')
  MODERATOR,
}

typedef GqlActivityCommentPostTypename = ({
  GqlUserUserPreview author,
  String body,
  String id,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  String title,
  String typeName,
});
GqlActivityCommentPostTypename deserializeGqlActivityCommentPostTypename(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
    typeName: json['__typename'] as String,
  );
}

typedef GqlCommentBodyId = ({String body, String id});
GqlCommentBodyId deserializeGqlCommentBodyId(Map<String, dynamic> json) {
  return (body: json['body'] as String, id: json['id'] as String);
}

typedef GqlCommentCommentWithAuthor = ({
  GqlUserUserPreview author,
  String body,
  String id,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
});
GqlCommentCommentWithAuthor deserializeGqlCommentCommentWithAuthor(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
  );
}

typedef GqlCommentListAuthorBodyId = ({
  GqlUserName author,
  String body,
  String id,
});
GqlCommentListAuthorBodyId deserializeGqlCommentListAuthorBodyId(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserName,
    body: json['body'] as String,
    id: json['id'] as String,
  );
}

typedef GqlCommentListCommentWithAuthor = ({
  GqlUserUserPreview author,
  String body,
  String id,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
});
GqlCommentListCommentWithAuthor deserializeGqlCommentListCommentWithAuthor(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
  );
}

typedef GqlCommentWithAuthor = ({
  GqlUserUserPreview author,
  String body,
  String id,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
});
GqlCommentWithAuthor deserializeGqlCommentWithAuthor(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
  );
}

typedef GqlCreatePost = ({
  GqlUserUserPreview author,
  String body,
  GqlCommentCommentWithAuthor commentsBy,

  ///  Create a post
  GqlPostPostFull createPost,
  String id,
  GqlUserUserPreview likedBy,
  GqlMetadataCreatedAtIsPublishedRating metadata,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  GqlStatsLikesReactionsViews stats,
  List<String> tags,
  String title,
});
GqlCreatePost deserializeGqlCreatePost(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    commentsBy:
        (json['commentsBy'] ?? json['comments']) as GqlCommentCommentWithAuthor,
    createPost: deserializeGqlPostPostFull(
      json['createPost'] as Map<String, dynamic>,
    ),
    id: json['id'] as String,
    likedBy: json['likedBy'] as GqlUserUserPreview,
    metadata: json['metadata'] as GqlMetadataCreatedAtIsPublishedRating,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    stats: json['stats'] as GqlStatsLikesReactionsViews,
    tags: (json['tags'] as List).map((e) => e as String).toList(),
    title: json['title'] as String,
  );
}

typedef GqlCreatePostVariables = ({GqlPostInput input});
GqlCreatePostVariables deserializeGqlCreatePostVariables(
  Map<String, dynamic> json,
) {
  return (
    input: deserializeGqlPostInput(json['input'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> serializeGqlCreatePostVariables(
  GqlCreatePostVariables data,
) {
  return {'input': serializeGqlPostInput((data.input as GqlPostInput))};
}

typedef GqlFooPost = ({
  GqlUserUserPreview author,
  String body,
  GqlCommentCommentWithAuthor commentsBy,

  ///  Create a post
  GqlPostPostFull createPost,
  String id,
  GqlUserUserPreview likedBy,
  GqlMetadataCreatedAtIsPublishedRating metadata,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  GqlStatsLikesReactionsViews stats,
  List<String> tags,
  String title,
});
GqlFooPost deserializeGqlFooPost(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    commentsBy:
        (json['commentsBy'] ?? json['comments']) as GqlCommentCommentWithAuthor,
    createPost: deserializeGqlPostPostFull(
      json['createPost'] as Map<String, dynamic>,
    ),
    id: json['id'] as String,
    likedBy: json['likedBy'] as GqlUserUserPreview,
    metadata: json['metadata'] as GqlMetadataCreatedAtIsPublishedRating,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    stats: json['stats'] as GqlStatsLikesReactionsViews,
    tags: (json['tags'] as List).map((e) => e as String).toList(),
    title: json['title'] as String,
  );
}

typedef GqlFooPostVariables = ({GqlPostInput input});
GqlFooPostVariables deserializeGqlFooPostVariables(Map<String, dynamic> json) {
  return (
    input: deserializeGqlPostInput(json['input'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> serializeGqlFooPostVariables(GqlFooPostVariables data) {
  return {'input': serializeGqlPostInput((data.input as GqlPostInput))};
}

typedef GqlGetUserAndSearch = ({
  GqlUserUserPreview author,
  String? bio,
  String body,
  GqlCommentCommentWithAuthor commentsBy,
  GqlPostPostPreview favoritePost,
  GqlUserUserPreview friends,
  String id,
  GqlUserUserPreview likedBy,
  GqlMetadataCreatedAtIsPublishedRating metadata,
  String name,
  GqlPostPostFullComments posts,
  GqlCommentBodyId replies,
  GqlRole? role,
  GqlSearchResultCommentPostUserTypename search,
  GqlStatsLikesReactionsViews stats,
  List<String> tags,
  String title,
  GqlUserUserFull user,
});
GqlGetUserAndSearch deserializeGqlGetUserAndSearch(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    bio: json['bio'] as String?,
    body: json['body'] as String,
    commentsBy:
        (json['commentsBy'] ?? json['comments']) as GqlCommentCommentWithAuthor,
    favoritePost: json['favoritePost'] as GqlPostPostPreview,
    friends: json['friends'] as GqlUserUserPreview,
    id: json['id'] as String,
    likedBy: json['likedBy'] as GqlUserUserPreview,
    metadata: json['metadata'] as GqlMetadataCreatedAtIsPublishedRating,
    name: json['name'] as String,
    posts: json['posts'] as GqlPostPostFullComments,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    search: json['search'] as GqlSearchResultCommentPostUserTypename,
    stats: json['stats'] as GqlStatsLikesReactionsViews,
    tags: (json['tags'] as List).map((e) => e as String).toList(),
    title: json['title'] as String,
    user: json['user'] as GqlUserUserFull,
  );
}

typedef GqlGetUserAndSearchVariables = ({
  String id,
  String term,
  bool withComments,
});
GqlGetUserAndSearchVariables deserializeGqlGetUserAndSearchVariables(
  Map<String, dynamic> json,
) {
  return (
    id: json['id'] as String,
    term: json['term'] as String,
    withComments: json['withComments'] as bool,
  );
}

Map<String, dynamic> serializeGqlGetUserAndSearchVariables(
  GqlGetUserAndSearchVariables data,
) {
  return {'id': data.id, 'term': data.term, 'withComments': data.withComments};
}

typedef GqlLikeToggleResultSuccessTarget = ({
  bool success,
  GqlNodeCommentPostUserTypename target,
});
GqlLikeToggleResultSuccessTarget deserializeGqlLikeToggleResultSuccessTarget(
  Map<String, dynamic> json,
) {
  return (
    success: json['success'] as bool,
    target: json['target'] as GqlNodeCommentPostUserTypename,
  );
}

typedef GqlMetadataCreatedAtIsPublishedRating = ({
  String? createdAt,
  bool isPublished,
  double? rating,
});
GqlMetadataCreatedAtIsPublishedRating
deserializeGqlMetadataCreatedAtIsPublishedRating(Map<String, dynamic> json) {
  return (
    createdAt: json['createdAt'] as String?,
    isPublished: json['isPublished'] as bool,
    rating: json['rating'] as double?,
  );
}

///  Metadata input
class GqlMetadataInput {
  const GqlMetadataInput({this.isPublished, this.not, this.rIn, this.rating});
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
              : deserializeGqlMetadataInput(
                  json['not'] as Map<String, dynamic>,
                ),
    rIn: json['in'] == null
        ? null
        : () => (json['in'] as List?)
              ?.map(
                (e) => e == null
                    ? null
                    : deserializeGqlMetadataInput(e as Map<String, dynamic>),
              )
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
        ?.map(
          (e) => e == null
              ? null
              : serializeGqlMetadataInput((e! as GqlMetadataInput)),
        )
        .toList();
  }
  return _result;
}

typedef GqlNodeCommentPostUserTypename = ({
  String age,
  GqlUserName author,
  String body,
  String fullName,
  String id,
  String name,
  GqlStatsLikesReactions stats,
  String title,
  String typeName,
});
GqlNodeCommentPostUserTypename deserializeGqlNodeCommentPostUserTypename(
  Map<String, dynamic> json,
) {
  return (
    age: json['age'] as String,
    author: json['author'] as GqlUserName,
    body: json['body'] as String,
    fullName: json['fullName'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    stats: json['stats'] as GqlStatsLikesReactions,
    title: json['title'] as String,
    typeName: json['__typename'] as String,
  );
}

typedef GqlOnActivity = ({
  GqlActivityCommentPostTypename activity,
  GqlUserUserPreview author,
  String body,
  String id,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  String title,
});
GqlOnActivity deserializeGqlOnActivity(Map<String, dynamic> json) {
  return (
    activity: json['activity'] as GqlActivityCommentPostTypename,
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

typedef GqlOnPostAdded = ({
  GqlUserUserPreview author,
  String id,
  String name,
  GqlPostPostPreview postAdded,
  GqlRole? role,
  String title,
});
GqlOnPostAdded deserializeGqlOnPostAdded(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    id: json['id'] as String,
    name: json['name'] as String,
    postAdded: json['postAdded'] as GqlPostPostPreview,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

typedef GqlPostFull = ({
  GqlUserUserPreview author,
  String body,
  GqlCommentCommentWithAuthor commentsBy,
  String id,
  GqlUserUserPreview likedBy,
  GqlMetadataCreatedAtIsPublishedRating metadata,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  GqlStatsLikesReactionsViews stats,
  List<String> tags,
  String title,
});
GqlPostFull deserializeGqlPostFull(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    commentsBy:
        (json['commentsBy'] ?? json['comments']) as GqlCommentCommentWithAuthor,
    id: json['id'] as String,
    likedBy: json['likedBy'] as GqlUserUserPreview,
    metadata: json['metadata'] as GqlMetadataCreatedAtIsPublishedRating,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    stats: json['stats'] as GqlStatsLikesReactionsViews,
    tags: (json['tags'] as List).map((e) => e as String).toList(),
    title: json['title'] as String,
  );
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

typedef GqlPostListIdStatsTitle = ({
  String id,
  GqlStatsLikesReactions stats,
  String title,
});
GqlPostListIdStatsTitle deserializeGqlPostListIdStatsTitle(
  Map<String, dynamic> json,
) {
  return (
    id: json['id'] as String,
    stats: json['stats'] as GqlStatsLikesReactions,
    title: json['title'] as String,
  );
}

typedef GqlPostListPostPreview = ({
  GqlUserUserPreview author,
  String id,
  String name,
  GqlRole? role,
  String title,
});
GqlPostListPostPreview deserializeGqlPostListPostPreview(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserUserPreview,
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

typedef GqlPostPostFull = ({
  GqlUserUserPreview author,
  String body,
  GqlCommentCommentWithAuthor commentsBy,
  String id,
  GqlUserUserPreview likedBy,
  GqlMetadataCreatedAtIsPublishedRating metadata,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  GqlStatsLikesReactionsViews stats,
  List<String> tags,
  String title,
});
GqlPostPostFull deserializeGqlPostPostFull(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    commentsBy:
        (json['commentsBy'] ?? json['comments']) as GqlCommentCommentWithAuthor,
    id: json['id'] as String,
    likedBy: json['likedBy'] as GqlUserUserPreview,
    metadata: json['metadata'] as GqlMetadataCreatedAtIsPublishedRating,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    stats: json['stats'] as GqlStatsLikesReactionsViews,
    tags: (json['tags'] as List).map((e) => e as String).toList(),
    title: json['title'] as String,
  );
}

typedef GqlPostPostFullComments = ({
  GqlUserUserPreview author,
  String body,
  GqlCommentCommentWithAuthor comments,
  GqlCommentCommentWithAuthor commentsBy,
  String id,
  GqlUserUserPreview likedBy,
  GqlMetadataCreatedAtIsPublishedRating metadata,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  GqlStatsLikesReactionsViews stats,
  List<String> tags,
  String title,
});
GqlPostPostFullComments deserializeGqlPostPostFullComments(
  Map<String, dynamic> json,
) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    comments: json['comments'] as GqlCommentCommentWithAuthor,
    commentsBy:
        (json['commentsBy'] ?? json['comments']) as GqlCommentCommentWithAuthor,
    id: json['id'] as String,
    likedBy: json['likedBy'] as GqlUserUserPreview,
    metadata: json['metadata'] as GqlMetadataCreatedAtIsPublishedRating,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    stats: json['stats'] as GqlStatsLikesReactionsViews,
    tags: (json['tags'] as List).map((e) => e as String).toList(),
    title: json['title'] as String,
  );
}

typedef GqlPostPostPreview = ({
  GqlUserUserPreview author,
  String id,
  String name,
  GqlRole? role,
  String title,
});
GqlPostPostPreview deserializeGqlPostPostPreview(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

typedef GqlPostPreview = ({
  GqlUserUserPreview author,
  String id,
  String name,
  GqlRole? role,
  String title,
});
GqlPostPreview deserializeGqlPostPreview(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

typedef GqlSearchResultCommentPostUserTypename = ({
  GqlUserUserPreview author,
  String body,
  String id,
  String name,
  GqlCommentBodyId replies,
  GqlRole? role,
  String title,
  String typeName,
});
GqlSearchResultCommentPostUserTypename
deserializeGqlSearchResultCommentPostUserTypename(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    body: json['body'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    replies: json['replies'] as GqlCommentBodyId,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
    typeName: json['__typename'] as String,
  );
}

typedef GqlStatsLikesReactions = ({int likes, List<GqlReaction> reactions});
GqlStatsLikesReactions deserializeGqlStatsLikesReactions(
  Map<String, dynamic> json,
) {
  return (
    likes: json['likes'] as int,
    reactions: (json['reactions'] as List)
        .map((e) => GqlReaction.values.byName(e as String))
        .toList(),
  );
}

typedef GqlStatsLikesReactionsViews = ({
  int likes,
  List<GqlReaction> reactions,
  int views,
});
GqlStatsLikesReactionsViews deserializeGqlStatsLikesReactionsViews(
  Map<String, dynamic> json,
) {
  return (
    likes: json['likes'] as int,
    reactions: (json['reactions'] as List)
        .map((e) => GqlReaction.values.byName(e as String))
        .toList(),
    views: json['views'] as int,
  );
}

typedef GqlToggleLike = ({GqlLikeToggleResultSuccessTarget toggleLike});
GqlToggleLike deserializeGqlToggleLike(Map<String, dynamic> json) {
  return (toggleLike: json['toggleLike'] as GqlLikeToggleResultSuccessTarget);
}

typedef GqlToggleLikeVariables = ({String id, bool? rOn});
GqlToggleLikeVariables deserializeGqlToggleLikeVariables(
  Map<String, dynamic> json,
) {
  return (id: json['id'] as String, rOn: json['on'] as bool?);
}

Map<String, dynamic> serializeGqlToggleLikeVariables(
  GqlToggleLikeVariables data,
) {
  return {'id': data.id, 'on': data.rOn};
}

///  User is someone
typedef GqlUserFull = ({
  GqlUserUserPreview author,
  String? bio,
  GqlPostPostPreview favoritePost,
  GqlUserUserPreview friends,
  String id,
  String name,
  GqlPostPostPreview posts,
  GqlRole? role,
  String title,
});
GqlUserFull deserializeGqlUserFull(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    bio: json['bio'] as String?,
    favoritePost: json['favoritePost'] as GqlPostPostPreview,
    friends: json['friends'] as GqlUserUserPreview,
    id: json['id'] as String,
    name: json['name'] as String,
    posts: json['posts'] as GqlPostPostPreview,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

///  User is someone
typedef GqlUserListAgeFullNameIdName = ({
  String age,
  String fullName,
  String id,
  String name,
});
GqlUserListAgeFullNameIdName deserializeGqlUserListAgeFullNameIdName(
  Map<String, dynamic> json,
) {
  return (
    age: json['age'] as String,
    fullName: json['fullName'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

///  User is someone
typedef GqlUserListUserPreview = ({String id, String name, GqlRole? role});
GqlUserListUserPreview deserializeGqlUserListUserPreview(
  Map<String, dynamic> json,
) {
  return (
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
  );
}

///  User is someone
typedef GqlUserName = ({String name});
GqlUserName deserializeGqlUserName(Map<String, dynamic> json) {
  return (name: json['name'] as String);
}

///  User is someone
typedef GqlUserPreview = ({String id, String name, GqlRole? role});
GqlUserPreview deserializeGqlUserPreview(Map<String, dynamic> json) {
  return (
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
  );
}

///  User is someone
typedef GqlUserUserFull = ({
  GqlUserUserPreview author,
  String? bio,
  GqlPostPostPreview favoritePost,
  GqlUserUserPreview friends,
  String id,
  String name,
  GqlPostPostPreview posts,
  GqlRole? role,
  String title,
});
GqlUserUserFull deserializeGqlUserUserFull(Map<String, dynamic> json) {
  return (
    author: json['author'] as GqlUserUserPreview,
    bio: json['bio'] as String?,
    favoritePost: json['favoritePost'] as GqlPostPostPreview,
    friends: json['friends'] as GqlUserUserPreview,
    id: json['id'] as String,
    name: json['name'] as String,
    posts: json['posts'] as GqlPostPostPreview,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
    title: json['title'] as String,
  );
}

///  User is someone
typedef GqlUserUserPreview = ({String id, String name, GqlRole? role});
GqlUserUserPreview deserializeGqlUserUserPreview(Map<String, dynamic> json) {
  return (
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] == null
        ? null
        : GqlRole.values.byName(json['role'] as String),
  );
}
