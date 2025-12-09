# GraphQL Client Code Generator (Dart + code_builder)

## Overview

This project is a **client-side GraphQL code generator** for Dart. It reads:

- A **schema** file: `schema.graphql`
- A set of **operation documents**: queries, mutations, subscriptions, fragments (`*.graphql`)
- A `config.yaml` for customization

It outputs **Dart typedef record types** and helpers, using `code_builder`, with:

- Types generated **only for selections used by operations**
- Reuse of typedefs for shared structures (e.g. fragments, repeated outputs)
- Support for **fragment spreads with maybe-semantics** (similar to Ferry) ex: myResponse.foo.spreadField.when(typeA: (value) => doA, typeB: (value) => doB), or switch(myResponse.foo.spreadField) {
    TypeA => doA,
    TypeB => doB,
    _ => throw UninpmelentedError()
}
- Pattern matching support for **interfaces and unions**
- Generated **serialize** / **deserialize** functions per input / response, nested fragments should be separate serializers and deserializers
- Hardcoded, **compressed operation strings** (no AST emitted)
- No dependency on `build_runner`
- Target: **100% test coverage**
- Keep principlec like: SOLID, KISS, DRY, the code should be documented and well tested, easy to maintain
- Generate schema file as single unit, operations file as a single unit.
The generator runs as a **CLI** (e.g. `dart run shazam build`).
- Allow alias support


Total coverage must reach 100%.
Tests must verify:

Area	Must test
Schema parsing	interfaces, unions, enums, scalars, directives
Operations	queries, mutations, subscriptions
Fragments	spreads, nested, inline
Aliases	field Aliasing behavior
Typedef output	correct nullability + list handling
Serialization	deep nested JSON, custom scalars
Pattern matching	unions + maybe() fallback
Compression	decompression yields original source
File generation	golden compare for expected code

---

## Scope & Requirements

### Inputs

- `config.yaml` – Configuration for scalar mapping and output options
- watch mode, with --watch flag

#### `config.yaml` shape

```yaml
scalars: # Import and reference types listed, default scalar mapping could be overrideen here
  DateTime: # Representing Type in graphql
    name: "DateTimeClass" # Representing class or object name in dart
    path: "package:mypackage/date_time_class.dart" # example import path
  UUID: "String" # Raw mapping for string, via typedef
  JSON: "Map<String, dynamic>"
output_dir: generated # Outputs placed relative to their source graphql within this directory
input_dir: lib/
nullable_mode: required  # or "optional"
name_prefix: "Gql"
compress_queries: true
emit_helpers: true
```

### Behavior (refined):

output_dir: base directory for generated Dart, created **relative to each source GraphQL file's directory**; generator creates subdirectories as needed.
input_dir: root for GraphQL discovery; scan recursively for `.graphql` (queries, mutations, subscriptions, fragments).
schema: path to `schema.graphql`, resolved relative to the `config.yaml` location (or absolute).
nullable_mode (supported values: `required`, `optional`):
  - required: mirror GraphQL nullability exactly (`!` => non-nullable); list wrappers observe both outer/inner nullability.
  - optional: same rules, but any type without `!` (including list wrappers) is nullable (e.g., `[User!]` => `List<User?>?`, `[User]!` => `List<User?>`).
name_prefix: prefix for generated typedef names (operations, fragments, helpers).
compress_queries: when true, emit Base64-encoded gzip (zlib) compressed operation strings; whitespace minimization is allowed but not required beyond GraphQL spec compliance.
emit_helpers: when true, emit shared helpers (pattern match, serializers registry, decompression helper).

# Mandatory verification
The generated output must be run on spec_suite, and the output must be valid dart code, runnable

---

## Additional specification decisions

- Scalars:
  - Built-ins default: `String` (ID/String), `int` (Int), `double` (Float), `bool` (Boolean).
  - Mapping via `scalars`:
    - Scalar mapped to string => typedef alias to that Dart type.
    - Scalar mapped to object with `name`/`path` => import `path` and use `name` directly (no typedef).
  - Unknown scalars without mapping are a build error.
- Output layout:
  - Emit per-operation files under `output_dir/operations` (`<operationName>.dart`), per-fragment files under `output_dir/fragments`, shared helpers under `output_dir/helpers.dart`, and a barrel `output_dir/index.dart` exporting all.
  - Generated files are deterministic (sorted by operation/fragment name).
- Fragments & maybe semantics:
  - For each fragment, emit a typedef for its selection.
  - For spreads/inline fragments, generate `maybe<FragmentName>` accessors that return `<FragmentName>?` guarded by `__typename` checks.
- Pattern matching:
  - For interfaces/unions, generate helper functions `when`/`maybeWhen` that dispatch on `__typename` to the proper typedef shape; include `__typename` in all response typedefs.
- Serialization:
  - Every typedef gets `toJson`/`fromJson`; nested fragments and aliases are serialized using the aliased field names; custom scalars delegate to their mapped Dart types.
- Aliases:
  - Field names in Dart honor GraphQL aliases; convert to `camelCase` and suffix `_` if needed to avoid identifier collisions.
- Watch mode/CLI:
  - CLI supports `build` and `build --watch`; watch performs incremental rebuild on changes to `input_dir`, `schema`, or `config.yaml`.
- Errors:
  - Validation failures (missing schema, unknown scalar, invalid config) fail fast with clear messages.

# Mandatory verification
The generated output must be run on spec_suite, and the output must be valid dart code, runnable



Make sure that the arhitecture of the plugin is consistent, there are steps that the library should follow:
Parsing, generating IR (intermediate representation), then generating output (maybe a pipeline structure?)

Allowing developers (library consumers) to write plugins is also a must, so they can extends functionality.

Support directives, like directive @_upper on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT
directives starting with _ are local, they are not outputted in the query string itself, just in code. (so they are not sent over the wire)
