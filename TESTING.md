# Testing Strategy

## How to run
- `dart run bin/shazam.dart build --config config.yaml` — generate outputs for fixtures.
- `dart test` — execute unit and golden tests (add tests under `test/`).

## Fixtures layout
- Inputs live under `spec_suite/` (e.g., `schema.graphql`, `operations.graphql`, optional `config.yaml`).
- Expected outputs: generated files under `spec_suite/generated` (goldens). Golden tests should diff actual vs expected.

## Coverage targets by feature

| Feature           | Coverage target                                                |
| ----------------- | -------------------------------------------------------------- |
| Scalars           | Parsing, custom inline/imported mappings, unknown scalar error |
| Enums             | Parsing, usage, extensions (enum extension)                    |
| Objects           | Fields, nested selections, alias mapping                       |
| Interfaces        | Fragment spreads, type resolution, typename mapping            |
| Unions            | Inline fragments & polymorphic helpers                         |
| Input Objects     | Nesting, default values, nullability                           |
| Lists             | Nullability edges: `T`, `T!`, `[T]`, `[T!]`, `[T]!`, `[T!]!`   |
| Variables         | Type coercion, default values, missing vars                    |
| Directives        | `@include`, `@skip`, custom directives handling                |
| Fragments         | Named, inline, invalid spreads, fragment const emission        |
| Schema Extensions | Type extension, enum extension, field extension                |
| Mutations         | Required args, input type validation                           |
| Subscriptions     | Existence, structure validation                                |
| Validation Errors | Unknown fields, type mismatches, invalid fragments             |
| Typename          | `__typename` → `typeName` mapping, always string               |
| Requests          | Operation request builders include `query` and optional vars   |
| Serialization     | Nested serializer/deserializer calls, null handling            |
| Compression       | Raw vs compressed query strings (when enabled)                 |
| Config validation | Missing schema/input_dir, invalid name_prefix, bad scalars     |
| Watch mode        | Change detection, debounce, rebuild correctness (if enabled)   |

## Expectations per area
- **Goldens**: Generated Dart must match expected under `spec_suite/generated` for all fixtures.
- **Errors**: Invalid inputs should surface clear errors (schema/operation/config), not partial builds.
- **Determinism**: Output ordering stable across runs; record reuse consistent across documents.
- **Typename**: `typeName` field always present and serialized as `__typename`.
- **Serializers**: Nested records invoke child serializers/deserializers; list handling preserves nullability.
- **Operations**: Operation strings are raw or compressed per config; request builders emit `{query, variables?}`.

## Adding new tests/fixtures
- Add schema and operations under a new `spec_suite/<case>/` (or reuse existing).
- Generate outputs with the CLI and store under `spec_suite/<case>/generated`.
- Add a test referencing the fixture and asserting golden match + error behavior as needed.
