import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final configs = Directory('test/spec_suite')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => p.basename(f.path) == 'config.yaml')
      .map((f) => p.normalize(f.path))
      .toList()
    ..sort();

  
    for (final config in configs) {
      test(skip: true, 'builds every spec_suite config with shazam for $config', () async {
        final result = Process.runSync(
          'dart',
          ['run', 'bin/shazam.dart', 'build', '--config', config],
          
        );
        if (result.exitCode != 0) {
          fail(
              'shazam failed for $config (exit ${result.exitCode})\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}');
        }
      }, timeout: const Timeout(Duration(minutes: 10)));    
    }
  
}
