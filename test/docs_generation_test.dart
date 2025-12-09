import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('type descriptions are emitted on generated records', () {
    final opOut =
        File('test/spec_suite/golden/generated/operations/ToggleLike.dart').readAsStringSync();
    expect(opOut, contains('///  User is someone'));
  });

  test('field descriptions (e.g., root operations) are emitted', () {
    final opOut =
        File('test/spec_suite/golden/generated/operations/CreatePost.dart').readAsStringSync();
    expect(opOut, contains('///  Create a post'));
  });
}
