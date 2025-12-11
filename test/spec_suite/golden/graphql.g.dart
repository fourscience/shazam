import 'dart:convert';
import 'dart:io' show gzip;
import '__generated__/CreatePost.dart';
import '__generated__/GetUserAndSearch.dart';
import '__generated__/OnActivity.dart';
import '__generated__/OnPostAdded.dart';
import '__generated__/ToggleLike.dart';
import 'nested/query/__generated__/FooPost.dart';

// Generated helpers
String decompress(String input) =>
    utf8.decode(gzip.decode(base64Decode(input)));
const _interfaceImpls = <String, Set<String>>{
  'Node': {'User', 'Comment', 'Post'},
  'Person': {'User'},
};

const _unionVariants = <String, Set<String>>{
  'Activity': {'Post', 'Comment'},
  'SearchResult': {'User', 'Post', 'Comment'},
};

bool isTypeName(dynamic record, String expected) {
  final typeName = (record as dynamic).typeName;
  return typeName == expected;
}

/// Checks if a record matches a concrete type, interface, or union name.
bool isTypeOf(dynamic record, String target) {
  final typeName = (record as dynamic).typeName;
  if (typeName == target) return true;
  final impls = _interfaceImpls[target];
  if (impls != null && impls.contains(typeName)) return true;
  final variants = _unionVariants[target];
  if (variants != null && variants.contains(typeName)) return true;
  return false;
}

typedef ResponseParser<T> = T Function(Map<String, dynamic>);
final responseParsers = <String, dynamic Function(Map<String, dynamic>)>{
  'GqlCreatePost': parseGqlCreatePostResponse,
  'GqlGetUserAndSearch': parseGqlGetUserAndSearchResponse,
  'GqlOnActivity': parseGqlOnActivityResponse,
  'GqlOnPostAdded': parseGqlOnPostAddedResponse,
  'GqlToggleLike': parseGqlToggleLikeResponse,
  'GqlFooPost': parseGqlFooPostResponse,
};
dynamic Function(Map<String, dynamic>)? resolveParser(String key) =>
    responseParsers[key];
