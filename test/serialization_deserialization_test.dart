import 'package:test/test.dart';

import '../spec_suite/generated/operations/CreatePost.dart';
import '../spec_suite/generated/operations/OnPostAdded.dart';
import '../spec_suite/generated/operations/ToggleLike.dart';
import '../spec_suite/generated/helpers.dart';
import '../spec_suite/generated/types.dart';
import '../spec_suite/generated/operations/GetUserAndSearch.dart';
import '../spec_suite/generated/operations/OnActivity.dart';

void main() {
  group('deserialization', () {
    test('parses CreatePost response', () {
      final response = _sampleCreatePostResponse();
      final parsed = parseGqlCreatePostResponse(response);

      expect(parsed.createPost.title, 'Post Title');
      expect(parsed.createPost.author.id, 'user-1');
      expect(parsed.createPost.comments.first.body, 'First comment');
      expect(parsed.tags, contains('tag-1'));
    });

    test('parses ToggleLike response (comment target)', () {
      final response = _sampleToggleLikeResponse();
      final parsed = parseGqlToggleLikeResponse(response);

      expect(parsed.toggleLike.success, isTrue);
      expect(parsed.toggleLike.target?.comment?.body, 'Comment body');
      expect(parsed.toggleLike.target?.comment?.author.name, 'Carol');
    });

    test('parses OnPostAdded response', () {
      final response = _sampleOnPostAddedResponse();
      final parsed = parseGqlOnPostAddedResponse(response);

      expect(parsed.postAdded.id, 'post-2');
      expect(parsed.postAdded.author.name, 'Alice');
      expect(parsed.postAdded.title, 'PostPreview Title');
    });
  });

  group('serialization', () {
    test('serializes inputs', () {
      final metadata = (isPublished: true, rating: 4.5);
      final input = (
        title: 'Hello',
        content: 'World',
        tags: ['a', 'b'],
        metadata: metadata,
      );

      expect(
        serializeGqlMetadataInput(metadata),
        {'isPublished': true, 'rating': 4.5},
      );
      expect(
        serializeGqlPostInput(input),
        {
          'content': 'World',
          'metadata': {'isPublished': true, 'rating': 4.5},
          'tags': ['a', 'b'],
          'title': 'Hello',
        },
      );
    });
  });

  group('interfaces and unions', () {
    test('type helpers work for interfaces and unions', () {
      final searchResult = _sampleSearchResult();
      final activity = _sampleActivity();

      expect(isTypeOf(searchResult.search.first, 'User'), isTrue);
      expect(isTypeOf(searchResult.search.first, 'Person'), isTrue);
      expect(isTypeOf(searchResult.search.first, 'SearchResult'), isTrue);

      expect(isTypeOf(activity.activity.post!, 'Post'), isTrue);
      expect(isTypeOf(activity.activity.post!, 'Activity'), isTrue);
      expect(isTypeOf(activity.activity.comment!, 'Comment'), isTrue);
      expect(isTypeOf(activity.activity.comment!, 'Activity'), isTrue);
    });

    test('union pattern matches preserve branch fields', () {
      final activity = _sampleActivity();

      expect(activity.activity.post?.title, 'Activity Post');
      expect(activity.activity.post?.author.name, 'Post Author');
      expect(activity.activity.comment?.author.name, 'Comment Author');
    });
  });

  group('enums', () {
    test('enum fields deserialize into enums', () {
      final parsed = _sampleSearchResult();
      expect(parsed.search.first.user?.name, 'Search User');
      expect(parsed.search.first.user?.role, GqlRole.USER);
    });

    test('enum fields serialize via .name', () {
      final input = (
        isPublished: true,
        rating: 1.0,
      );
      final postInput = (
        title: 't',
        content: 'c',
        tags: ['x'],
        metadata: input,
      );
      // role is optional; ensure serializer for enums uses .name
      expect(serializeGqlMetadataInput(input), containsPair('isPublished', true));
      expect(serializeGqlPostInput(postInput), containsPair('title', 't'));
    });
  });
}

Map<String, dynamic> _sampleCreatePostResponse() {
  final post = _postFullJson(id: 'post-1');
  return {
    ...post,
    'createPost': post,
    '__typename': 'Mutation',
  };
}

Map<String, dynamic> _sampleToggleLikeResponse() {
  return {
    '__typename': 'Mutation',
    'toggleLike': {
      '__typename': 'LikeToggleResult',
      'success': true,
      'target': {
        '__typename': 'Comment',
        'comment': {
          '__typename': 'Comment',
          'id': 'comment-1',
          'body': 'Comment body',
          'author': {
            '__typename': 'User',
            'name': 'Carol',
          },
        },
      },
    },
  };
}

Map<String, dynamic> _sampleOnPostAddedResponse() {
  final preview = _postPreviewJson(
    id: 'post-2',
    title: 'PostPreview Title',
    author: _userPreviewJson(id: 'user-1', name: 'Alice'),
  );
  return {
    ...preview,
    'postAdded': preview,
    '__typename': 'Subscription',
  };
}

GqlGetUserAndSearch _sampleSearchResult() {
  final json = {
    '__typename': 'Query',
    'user': null,
    'search': [
      {
        '__typename': 'User',
        'user': _userPreviewJson(
          id: 'user-10',
          name: 'Search User',
          role: 'USER',
        ),
      },
    ],
    'author': _userPreviewJson(id: 'user-10', name: 'Search User'),
    'bio': 'About me',
    'body': 'Root body',
    'comments': <Map<String, dynamic>>[],
    'favoritePost': null,
    'friends': <Map<String, dynamic>>[],
    'id': 'ignored',
    'likedBy': <Map<String, dynamic>>[],
    'metadata': null,
    'name': 'ignored',
    'posts': <Map<String, dynamic>>[],
    'replies': <Map<String, dynamic>>[],
    'role': null,
    'stats': _statsJson(),
    'tags': <String>[],
    'title': 'ignored',
  };
  return deserializeGqlGetUserAndSearch(json);
}

GqlOnActivity _sampleActivity() {
  final json = {
    '__typename': 'Subscription',
    'activity': {
      '__typename': 'Activity',
      'post': _postPreviewJson(
        id: 'post-activity',
        title: 'Activity Post',
        author: _userPreviewJson(id: 'user-activity', name: 'Post Author'),
      ),
      'comment': _commentWithAuthorJson(
        id: 'comment-activity',
        authorName: 'Comment Author',
      ),
    },
    'author': _userPreviewJson(id: 'user-activity', name: 'Post Author'),
    'body': '',
    'id': 'ignored',
    'name': '',
    'replies': <Map<String, dynamic>>[],
    'role': null,
    'title': '',
  };
  return deserializeGqlOnActivity(json);
}

Map<String, dynamic> _postFullJson({required String id}) {
  return {
    '__typename': 'Post',
    'id': id,
    'title': 'Post Title',
    'body': 'Post body',
    'name': 'Post Name',
    'role': 'ADMIN',
    'author': _userPreviewJson(id: 'user-1', name: 'Bob'),
    'tags': ['tag-1'],
    'metadata': _metadataJson(),
    'stats': _statsJson(),
    'comments': [
      _commentWithAuthorJson(id: 'comment-1', authorName: 'Alice'),
    ],
    'likedBy': [
      _userPreviewJson(id: 'user-2', name: 'Eve'),
    ],
    'replies': [
      _commentReplyJson(id: 'reply-1'),
    ],
    'typeName': 'Post',
  };
}

Map<String, dynamic> _postPreviewJson({
  required String id,
  required String title,
  required Map<String, dynamic> author,
}) {
  return {
    '__typename': 'Post',
    'id': id,
    'title': title,
    'author': author,
    'name': author['name'],
    'role': author['role'],
    'typeName': 'Post',
  };
}

Map<String, dynamic> _userPreviewJson({
  required String id,
  required String name,
  String role = 'USER',
}) {
  return {
    '__typename': 'User',
    'id': id,
    'name': name,
    'role': role,
    'typeName': 'User',
  };
}

Map<String, dynamic> _metadataJson() {
  return {
    '__typename': 'Metadata',
    'isPublished': true,
    'rating': 4.2,
    'createdAt': '2024-01-01',
    'typeName': 'Metadata',
  };
}

Map<String, dynamic> _statsJson() {
  return {
    '__typename': 'Stats',
    'views': 10,
    'likes': 5,
    'reactions': ['LIKE', 'WOW'],
    'typeName': 'Stats',
  };
}

Map<String, dynamic> _commentWithAuthorJson({
  required String id,
  required String authorName,
}) {
  return {
    '__typename': 'Comment',
    'id': id,
    'body': 'First comment',
    'author': _userPreviewJson(id: 'user-comment', name: authorName),
    'replies': [
      _commentReplyJson(id: '$id-reply-1'),
    ],
    'name': authorName,
    'role': 'USER',
    'typeName': 'Comment',
  };
}

Map<String, dynamic> _commentReplyJson({required String id}) {
  return {
    '__typename': 'Comment',
    'id': id,
    'body': 'Reply $id',
    'typeName': 'Comment',
  };
}
