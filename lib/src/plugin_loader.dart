import 'dart:async';
import 'dart:mirrors';

import 'package:path/path.dart' as p;
import 'package:shazam/src/config.dart';
import 'package:shazam/src/generator_plugin.dart';
import 'package:shazam/src/log.dart';

/// Loads GeneratorPlugin instances from the plugin paths configured in
/// config.yaml. Each plugin file must export either:
/// - a top-level `GeneratorPlugin plugin`
/// - a top-level `List<GeneratorPlugin> plugins`
/// - a top-level function `List<GeneratorPlugin> shazamPlugins()`
class PluginLoader {
  const PluginLoader();

  Future<List<GeneratorPlugin>> load(Config config) async {
    final loaded = <GeneratorPlugin>[];
    for (final path in config.pluginPaths) {
      final pluginUri = _toUri(path);
      try {
        final lib = await currentMirrorSystem().isolate.loadUri(pluginUri);
        final plugins = await _pluginsFromLibrary(lib);
        loaded.addAll(plugins);
        logInfo('Loaded ${plugins.length} plugin(s) from $path');
      } catch (e, st) {
        Error.throwWithStackTrace(
          StateError('Failed to load plugin at $path: $e'),
          st,
        );
      }
    }
    return loaded;
  }

  Uri _toUri(String path) {
    final normalized = p.normalize(path);
    return Uri.file(normalized);
  }

  Future<List<GeneratorPlugin>> _pluginsFromLibrary(
      LibraryMirror library) async {
    final candidates = <Symbol>[
      const Symbol('plugins'),
      const Symbol('plugin'),
      const Symbol('shazamPlugins'),
      const Symbol('loadPlugins'),
    ];
    for (final symbol in candidates) {
      if (!library.declarations.containsKey(symbol)) continue;
      final value = library.getField(symbol).reflectee;
      final plugins = await _asPlugins(value);
      if (plugins != null) {
        return plugins;
      }
    }
    throw StateError(
        'Plugin library must export `plugin`, `plugins`, or `shazamPlugins()` returning GeneratorPlugin(s).');
  }

  Future<List<GeneratorPlugin>?> _asPlugins(Object? value) async {
    if (value is GeneratorPlugin) {
      return [value];
    }
    if (value is List) {
      final plugins = value.whereType<GeneratorPlugin>().toList();
      if (plugins.isNotEmpty) return plugins;
    }
    if (value is Future) {
      return _asPlugins(await value);
    }
    if (value is Function) {
      final result = value();
      return _asPlugins(result);
    }
    return null;
  }
}
