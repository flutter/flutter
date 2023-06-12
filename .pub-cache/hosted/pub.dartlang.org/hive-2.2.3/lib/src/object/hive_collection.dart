part of hive;

/// List containing [HiveObjectMixin]s.
abstract class HiveCollection<E extends HiveObjectMixin> implements List<E> {
  /// The box which contains all the objects in this collection
  BoxBase get box;

  /// The keys of all the objects in this collection.
  Iterable<dynamic> get keys;

  /// Delete all objects in this collection from Hive.
  Future<void> deleteAllFromHive();

  /// Delete the first object in this collection from Hive.
  Future<void> deleteFirstFromHive();

  /// Delete the last object in this collection from Hive.
  Future<void> deleteLastFromHive();

  /// Delete the object at [index] from Hive.
  Future<void> deleteFromHive(int index);

  /// Converts this collection to a Map.
  Map<dynamic, E> toMap();
}
