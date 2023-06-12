part of hive;

/// Allows defining references to other [HiveObjectMixin]s.
@experimental
abstract class HiveList<E extends HiveObjectMixin> extends HiveCollection<E>
    implements List<E> {
  /// Create a new HiveList which can contain HiveObjects from [box].
  factory HiveList(Box box, {List<E>? objects}) =>
      HiveListImpl(box, objects: objects);

  /// Disposes this list. It is important to call this method when the list is
  /// no longer used to avoid memory leaks.
  void dispose();

  /// Casts the list to a new HiveList.
  HiveList<T> castHiveList<T extends HiveObjectMixin>();
}
