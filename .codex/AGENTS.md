# Shazam Codegen — Agent Field Guide

## What this repo does
- Generates Dart models + serializers from a GraphQL schema and operation documents.
- Entry points: CLI (`bin/shazam.dart`) and programmatic `Generator` (`lib/src/generator.dart`).
- Pipeline steps: load schema → load operations → merge → build IR → render Dart files → (optional) watch mode.

## Key runtime types
- `Config` (`lib/src/config.dart`): All user settings (paths, nullable mode, prefix, scalar mappings, plugins, keyword replacements). `Config.load` parses YAML; `.sanitizeIdentifier` handles Dart keyword clashes.
- `OperationsLoader` (`lib/src/operations_loader.dart`): Reads top-level `.graphql` files under `inputDir`; returns `OperationsBundle` of `DocumentSource`.
- `DocumentIr` & friends (`lib/src/document_ir.dart`): In-memory IR for operations, fragments, records, enums, and caches.
- Builders (`lib/src/builders/*`): Translate parsed GraphQL AST into IR.
  - `OperationBuilder`: Builds operations, variables, defaults, fragment dependencies.
  - `FragmentBuilder`: Caches fragments and stitches spread fields.
  - `InputBuilder` / `RecordBuilder`: Build records (inputs/outputs).
  - `IrBuildContext`: Shared config/schema/cache during IR build.
- `CodegenPipeline` (`lib/src/codegen_pipeline.dart`): Orchestrates schema load, operations load, IR build, render.
- `Renderer` (`lib/src/renderer.dart`): Default `CodeRenderer` writes Dart files using emitters:
  - `RecordEmitter`, `EnumEmitter`, `SerializerEmitter`, `OperationEmitter`.
  - Uses `NamingHelper`/`TypeHelper` to normalize names and unwrap types.
- `PluginLoader` (`lib/src/plugin_loader.dart`): Loads plugins from user-provided paths via `dart:mirrors` (`plugin`, `plugins`, or `shazamPlugins()` exports).
- `GeneratorPlugin` (`lib/src/generator_plugin.dart`): Hook points `onDocument`, `onLibrary`, `onRenderComplete`. `RenderContext` includes output directory; `CodegenContext` bundles IR and config.
- `ShazamWatcher` (`lib/src/shazam_watcher.dart`): Watches schema/config/ops for changes and reruns build in watch mode.

## CLI surface (`bin/shazam.dart`)
- `shazam build -c <config.yaml> [-w]`: Generate code (optionally watch).
- `shazam list -c <config.yaml>`: Print operations/fragments/scalars summary.
- Exits with 64 on usage/config errors; 1 on schema/ops parse errors.

## Typical flow (programmatic)
```dart
final config = await Config.load(File('config.yaml'));
final generator = Generator(config); // inject custom renderer/loader/plugins if needed
await generator.build();
```
- Under the hood: `CodegenPipeline` loads schema/operations, merges docs, builds IR, then `Renderer.render` writes output and invokes plugins.

## Plugins
- Export one of:
  - `const GeneratorPlugin plugin;`
  - `final List<GeneratorPlugin> plugins;`
  - `List<GeneratorPlugin> shazamPlugins()`
- Optional manifest: expose `PluginManifest pluginManifest`/`shazamPluginManifest()` with `id`, `version`, `capabilities` (`document|library|renderComplete`), optional op/fragment filters, and `requiresSandbox`.
- Loader returns `PluginRegistration` (plugin + manifest); renderer filters callbacks based on manifest and provides scoped `PluginServices` logging on `CodegenContext.services`.
- Hooks:
  - `onDocument(CodegenContext ctx)`: after IR built, before any rendering.
  - `onLibrary(LibraryBuilder library, CodegenContext ctx)`: mutate code_builder library per file; filtered by manifest patterns.
  - `onRenderComplete(CodegenContext ctx)`: after files for the document are written.
- Avoid mutating IR contents; prefer adding imports/declarations in `onLibrary`.

## Config essentials
- `output_dir`, `input_dir`, `schema`, `nullable_mode` (`required`/`optional`), `name_prefix`.
- Scalars: map GraphQL scalar → Dart symbol (`import` optional).
- `keyword_replacements`: map reserved identifiers → safe names.
- `plugins`: list of plugin file paths (resolved relative to config dir).
- `log_level`: `verbose|info|warn|warning|error|none` (default `info`); applied via `configureLogging`.

## Emitted files (default layout)
- `<outputDir>/schema.dart`: shared records/enums/helpers.
- `<outputDir>/operations/<Name>.dart`: per-operation request/response + helpers.
- `<outputDir>/fragments/<Name>.dart`: fragment consts + records.
- Optional `<outputDir>/helpers.dart` when `compressQueries` is true.

## Gotchas / guardrails
- Config validation fails when schema/input paths don’t exist or identifiers are invalid.
- Operations loader only reads top-level `.graphql` files (not recursive).
- Plugin load failures propagate with preserved stack traces; keep plugin files resolvable in package context.
- Watcher ignores missing targets but logs warnings.

## Tests in this repo (quick map)
- `test/config_load_test.dart`: Config loading/defaults and scalar/keyword parsing.
- `test/operations_loader_test.dart`: file discovery behavior.
- `test/naming_helper_test.dart`: naming/type helpers.
- `test/plugin_loader_test.dart` (+ fixtures): plugin export shapes.
- `test/operation_emitter_test.dart`: operation consts, compression, request builders.
- `test/codegen_pipeline_test.dart`: schema load error, document merge, render delegation.
- Existing integration/golden tests under `test/*generation_test.dart` cover end-to-end codegen.

## Useful commands
- Run full suite: `dart test`
- Targeted: `dart test test/operation_emitter_test.dart`
- CLI dry-run help: `dart run bin/shazam.dart` (shows usage when no args)
