extension XmlFlattenStreamExtension<T> on Stream<Iterable<T>> {
  /// Flattens a [Stream] of [Iterable] values of type [T] to a [Stream] of
  /// values of type [T].
  Stream<T> flatten() => expand((values) => values);
}
