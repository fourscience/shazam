import 'package:test/test.dart';

import '../spec_suite/generated/helpers.dart';
import '../spec_suite/generated/fragments/GqlPostPreview.dart';
import '../spec_suite/generated/operations/CreatePost.dart';
import '../spec_suite/generated/operations/GetUserAndSearch.dart';
import '../spec_suite/generated/operations/OnActivity.dart';
import '../spec_suite/generated/operations/ToggleLike.dart';
import '../spec_suite/schema.dart';

void main() {
  group('scalars & enums', () {
    test('scalar fields map to Dart primitives', () {
      final parsed = parseGqlToggleLikeResponse(_toggleLikeJson());
      expect(parsed.toggleLike.success, isA<bool>());
      expect(parsed.toggleLike.target?.post?.stats.likes, isA<int>());
    });

    test('enum fields map to Dart enums', () {
      final author = deserializeGqlPostPreviewAuthor({
        '__typename': 'User',
        'id': 'u1',
        'name': 'Enum User',
        'role': 'USER',
      });
      expect(author.role, GqlRole.USER);
    });
  });

  group('inputs & variables', () {
    test('input objects serialize with nested scalars/enums', () {
      final metadata =
          GqlMetadataInput(isPublished: true, rating: 3.2, not: null);
      final input = (
        title: 'Hi',
        content: 'Body',
        tags: ['x', 'y'],
        metadata: metadata,
      );
      expect(
        serializeGqlPostInput(input),
        {
          'content': 'Body',
          'metadata': {'isPublished': true, 'rating': 3.2},
          'tags': ['x', 'y'],
          'title': 'Hi',
        },
      );
    });

    test('request builders include variables', () {
      final vars = (
        input: (
          title: 'T',
          content: null,
          tags: <String>[],
          metadata: null,
        )
      );
      final req = buildGqlCreatePostRequest(variables: vars);
      expect(req['variables'], contains('input'));
      expect(req['query'], contains('mutation'));
    });
  });

  group('lists, interfaces, unions', () {
    test('lists stay non-nullable for non-null GraphQL lists', () {
      final parsed = parseGqlCreatePostResponse(_createPostJson());
      expect(parsed.createPost.likedBy, isA<List>());
      expect(parsed.createPost.likedBy, isNotEmpty);
    });

    test('interfaces resolved via helper', () {
      final post = deserializeGqlPostPreview(_postPreview(
          id: 'p1',
          title: 'Preview',
          author: _userPreview(id: 'u1', name: 'Author'))
        ..['name'] = 'Preview');
      expect(isTypeOf(post, 'Node'), isTrue);
    });

    test('unions expose when/maybeWhen helpers', () {
      final first = deserializeGqlGetUserAndSearchSearch({
        '__typename': 'SearchResult',
        'user': {
          '__typename': 'User',
          'id': 'u1',
          'name': 'Search User',
          'role': 'USER',
        }
      });
      final handled = first.when(
        () => 'unknown',
        user: (u) => u.name,
        post: (p) => p.title,
        comment: (_) => 'comment',
      );
      expect(handled, 'Search User');
      final maybe = first.maybeWhen(user: (u) => u.role?.name);
      expect(maybe, 'USER');
    });
  });

  group('fragments & inline fragments', () {
    test('fragment deserializers are reused', () {
      final parsed = parseGqlCreatePostResponse(_createPostJson());
      expect(parsed.createPost.author.name, 'Bob');
      expect(parsed.createPost.comments.first.author.name, 'Alice');
    });

    test('inline fragments populate variant fields', () {
      final parsed = parseGqlOnActivityResponse(_activityJson());
      expect(parsed.activity.post?.title, 'Activity Post');
      expect(parsed.activity.comment?.author.name, 'Comment Author');
    });
  });

  group('directives & aliasing', () {
    test('responses with directive-protected fields deserialize', () {
      final parsed = parseGqlCreatePostResponse(_createPostJson());
      expect(parsed.comments.first.replies, isNotNull);
    });

    test('typeName mapping keeps __typename accessible', () {
      final parsed = deserializeGqlPostPreview(_postPreview(
          id: 'p1',
          title: 'Preview',
          author: _userPreview(id: 'u1', name: 'Author'))
        ..['name'] = 'Preview');
      expect(parsed.typeName, 'Post');
    });
  });
}

Map<String, dynamic> _createPostJson() => {
      '__typename': 'Mutation',
      'author': _userPreview(id: 'user-1', name: 'Bob'),
      'body': 'Post body',
      'comments': [
        _commentWithAuthor(id: 'c1', authorName: 'Alice'),
      ],
      'createPost': {
        '__typename': 'Post',
        'author': _userPreview(id: 'user-1', name: 'Bob'),
        'body': 'Post body',
        'comments': [
          _commentWithAuthor(id: 'c1', authorName: 'Alice'),
        ],
        'id': 'post-1',
        'likedBy': [
          _userPreview(id: 'u2', name: 'Eve'),
        ],
        'metadata': _metadata(),
        'name': 'Post Name',
        'replies': [_commentReply(id: 'r1')],
        'role': 'USER',
        'stats': _stats(),
        'tags': ['tag-1'],
        'title': 'Post Title',
        'typeName': 'Post',
      },
      'id': 'post-1',
      'likedBy': [
        _userPreview(id: 'u2', name: 'Eve'),
      ],
      'metadata': _metadata(),
      'name': 'Post Name',
      'replies': [_commentReply(id: 'r1')],
      'role': 'USER',
      'stats': _stats(),
      'tags': ['tag-1'],
      'title': 'Post Title',
      'typeName': 'Mutation',
    };

Map<String, dynamic> _searchJson() => {
      '__typename': 'Query',
      'user': null,
      'search': [
        {
          '__typename': 'User',
          'user':
              _userPreview(id: 'user-10', name: 'Search User', role: 'USER'),
        }
      ],
      'posts': [
        {
          '__typename': 'Post',
          'id': 'post-1',
          'title': 'Post Title',
          'author': _userPreview(id: 'user-1', name: 'Bob'),
          'tags': ['tag-1'],
          'metadata': _metadata(),
          'stats': _stats(),
          'comments': [
            _commentWithAuthor(id: 'c1', authorName: 'Alice'),
          ],
          'likedBy': [
            _userPreview(id: 'u2', name: 'Eve'),
          ],
          'name': 'Post Title',
          'role': 'USER',
          'typeName': 'Post',
        }
      ],
      'author': _userPreview(id: 'user-1', name: 'Bob'),
      'bio': 'About me',
      'body': 'Root body',
      'comments': [_commentWithAuthor(id: 'c1', authorName: 'Alice')],
      'favoritePost': null,
      'friends': <Map<String, dynamic>>[],
      'id': 'ignored',
      'likedBy': [_userPreview(id: 'u2', name: 'Eve')],
      'metadata': _metadata(),
      'name': 'ignored',
      'replies': <Map<String, dynamic>>[],
      'role': 'USER',
      'stats': _stats(),
      'tags': <String>[],
      'title': 'ignored',
    };

Map<String, dynamic> _activityJson() => {
      '__typename': 'Subscription',
      'activity': {
        '__typename': 'Activity',
        'post': _postPreview(
          id: 'post-activity',
          title: 'Activity Post',
          author: _userPreview(id: 'user-activity', name: 'Post Author'),
        ),
        'comment': _commentWithAuthor(
          id: 'comment-activity',
          authorName: 'Comment Author',
        ),
        'name': '',
        'role': null,
      },
      'author': _userPreview(id: 'user-activity', name: 'Post Author'),
      'body': '',
      'id': 'ignored',
      'name': '',
      'replies': <Map<String, dynamic>>[],
      'role': null,
      'title': '',
    };

Map<String, dynamic> _toggleLikeJson() => {
      '__typename': 'Mutation',
      'toggleLike': {
        '__typename': 'LikeToggleResult',
        'success': true,
        'target': {
          '__typename': 'Post',
          'post': {
            '__typename': 'Post',
            'id': 'post-1',
            'stats': _stats(),
            'title': 'Post Title',
          }
        },
      },
    };

Map<String, dynamic> _userPreview({
  required String id,
  required String name,
  String role = 'USER',
}) =>
    {
      '__typename': 'User',
      'id': id,
      'name': name,
      'role': role,
      'typeName': 'User',
    };

Map<String, dynamic> _postPreview({
  required String id,
  required String title,
  required Map<String, dynamic> author,
}) =>
    {
      '__typename': 'Post',
      'id': id,
      'title': title,
      'author': author,
      'name': title,
      'role': null,
      'typeName': 'Post',
    };

Map<String, dynamic> _commentWithAuthor({
  required String id,
  required String authorName,
}) =>
    {
      '__typename': 'Comment',
      'id': id,
      'body': 'Comment $id',
      'author': _userPreview(id: 'u-$id', name: authorName),
      'replies': [_commentReply(id: '$id-r1')],
      'name': authorName,
      'role': 'USER',
      'typeName': 'Comment',
    };

Map<String, dynamic> _commentReply({required String id}) => {
      '__typename': 'Comment',
      'id': id,
      'body': 'Reply $id',
      'typeName': 'Comment',
    };

Map<String, dynamic> _metadata() => {
      '__typename': 'Metadata',
      'isPublished': true,
      'rating': 4.2,
      'createdAt': '2024-01-01',
    };

Map<String, dynamic> _stats() => {
      '__typename': 'Stats',
      'views': 10,
      'likes': 5,
      'reactions': ['LIKE', 'WOW'],
    };
