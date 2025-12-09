import 'dart:async';
import 'dart:io';

import 'package:watcher/watcher.dart';

import 'config.dart';
import 'log.dart';

class ShazamWatcher {
  ShazamWatcher(this.config, {required this.onChange});

  final Config config;
  final FutureOr<void> Function() onChange;

  StreamSubscription<WatchEvent>? _sub;

  Future<void> start() async {
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

    _sub = StreamGroup.merge(watchers).listen((event) async {
      logInfo('Change detected: ${event.path}');
      await onChange();
    });
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
