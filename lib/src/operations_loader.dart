import 'dart:io';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:path/path.dart' as p;

class OperationsLoader {
  OperationsLoader({required this.inputDir});
  final String inputDir;

  Future<OperationsBundle> load() async {
    final files = await _collectFiles();
    final docs = <DocumentSource>[];
    for (final file in files) {
      final content = await File(file).readAsString();
      docs.add(DocumentSource(path: file, document: parseString(content)));
    }
    return OperationsBundle(documents: docs);
  }

  Future<List<String>> _collectFiles() async {
    final result = <String>[];

    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      return result;
    }
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File &&
          p.extension(entity.path) == '.graphql' &&
          p.normalize(p.dirname(entity.path)) == p.normalize(inputDir)) {
        result.add(entity.path);
      }
    }
    return result;
  }
}

class OperationsBundle {
  OperationsBundle({required this.documents});
  final List<DocumentSource> documents;
}

class DocumentSource {
  DocumentSource({required this.path, required this.document});
  final String path;
  final DocumentNode document;
}
