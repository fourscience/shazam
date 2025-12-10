/// Base contract for codegen builders.
abstract mixin class Builder<R, S> {
  R build(S source);

  /// Convenience to build many sources.
  List<R> collect(Iterable<S> sources) => sources.map(build).toList();
}
