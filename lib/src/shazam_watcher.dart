import 'dart:async';
import 'dart:io';

import 'package:shazam/src/config.dart';
import 'package:shazam/src/log.dart';
import 'package:watcher/watcher.dart';

class ShazamWatcher {
  ShazamWatcher(this.config, {required this.onChange});

  final Config config;
  final FutureOr<void> Function() onChange;

  StreamSubscription<WatchEvent>? _sub;

  Future<void> start() {
    final targets = <String>{
      config.inputDir,
      config.schemaPath,
      config.configPath
    };
    final watchers = <Stream<WatchEvent>>[];
    for (final path in targets) {
      final stat = FileSystemEntity.typeSync(path);
      if (stat == FileSystemEntityType.notFound) {
        logWarn('Watch target missing: $path');
        continue;
      }
      if (stat == FileSystemEntityType.directory) {
        watchers.add(DirectoryWatcher(path).events);
      } else {
        watchers.add(FileWatcher(path).events);
      }
    }

    _sub = StreamGroup.merge(watchers).listen((event) {
      logInfo('Change detected: ${event.path}');
      final result = onChange();
      if (result is Future) {
        result.catchError((Object error, StackTrace stackTrace) {
          logError('Watch callback failed: $error');
          Error.throwWithStackTrace(error, stackTrace);
        });
      }
    });
    return Future.value();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}

class StreamGroup<T> {
  StreamGroup._(this.streams);
  final List<Stream<T>> streams;
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) =>
      StreamGroup._(streams.toList())._merge();
  Stream<T> _merge() async* {
    final controller = StreamController<T>();
    final subs = <StreamSubscription<T>>[];
    for (final stream in streams) {
      subs.add(stream.listen(controller.add));
    }
    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
    yield* controller.stream;
  }
}
