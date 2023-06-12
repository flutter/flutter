import 'package:hive/hive.dart';

/// Implemetation of [HiveCollection].
abstract class HiveCollectionMixin<E extends HiveObjectMixin>
    implements HiveCollection<E> {
  @override
  Iterable<dynamic> get keys sync* {
    for (var value in this) {
      yield value.key;
    }
  }

  @override
  Future<void> deleteAllFromHive() {
    return box.deleteAll(keys);
  }

  @override
  Future<void> deleteFirstFromHive() {
    return first.delete();
  }

  @override
  Future<void> deleteLastFromHive() {
    return last.delete();
  }

  @override
  Future<void> deleteFromHive(int index) {
    return this[index].delete();
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var item in this) {
      map[item.key] = item;
    }
    return map;
  }
}
