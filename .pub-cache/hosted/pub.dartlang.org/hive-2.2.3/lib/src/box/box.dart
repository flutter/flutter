part of hive;

/// Boxes contain all of your data. In the browser, each box has its own
/// IndexedDB database. On all other platforms, each Box is stored in a
/// separate file in the Hive home directory.
///
/// Write operations are asynchronous but the new values are immediately
/// available. The returned `Future` finishes when the change is written to
/// the backend. If this operation fails, the changes are being reverted.
///
/// Read operations for normal boxes are synchronous (the entries are in
/// memory). Lazy boxes have asynchronous read operations.
abstract class Box<E> implements BoxBase<E> {
  /// All the values in the box.
  ///
  /// The values are in the same order as their keys.
  Iterable<E> get values;

  /// Returns an iterable which contains all values starting with the value
  /// associated with [startKey] (inclusive) to the value associated with
  /// [endKey] (inclusive).
  ///
  /// If [startKey] does not exist, an empty iterable is returned. If [endKey]
  /// does not exist or is before [startKey], it is ignored.
  ///
  /// The values are in the same order as their keys.
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey});

  /// Returns the value associated with the given [key]. If the key does not
  /// exist, `null` is returned.
  ///
  /// If [defaultValue] is specified, it is returned in case the key does not
  /// exist.
  E? get(dynamic key, {E? defaultValue});

  /// Returns the value associated with the n-th key.
  E? getAt(int index);

  /// Returns a map which contains all key - value pairs of the box.
  Map<dynamic, E> toMap();
}
