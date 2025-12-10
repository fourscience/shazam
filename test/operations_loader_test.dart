import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shazam/src/operations_loader.dart';
import 'package:test/test.dart';

void main() {
  test('OperationsLoader reads only top-level .graphql files', () async {
    final dir = await Directory.systemTemp.createTemp('ops_loader_');
    addTearDown(() => dir.delete(recursive: true));

    final rootFile = File(p.join(dir.path, 'root.graphql'))
      ..writeAsStringSync('query Root { __typename }');
    Directory(p.join(dir.path, 'nested')).createSync();
    File(p.join(dir.path, 'nested', 'ignored.graphql'))
      .writeAsStringSync('query Ignored { __typename }');

    final loader = OperationsLoader(inputDir: dir.path);
    final bundle = await loader.load();

    expect(bundle.documents, hasLength(1));
    expect(bundle.documents.first.path, rootFile.path);
  });

  test('OperationsLoader returns empty bundle when directory is missing',
      () async {
    final loader = OperationsLoader(inputDir: '/path/does/not/exist');
    final bundle = await loader.load();

    expect(bundle.documents, isEmpty);
  });
}
