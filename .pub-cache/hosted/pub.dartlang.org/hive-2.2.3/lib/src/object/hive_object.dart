library hive_object_internal;

import 'package:hive/hive.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:meta/meta.dart';

part 'hive_object_internal.dart';

/// Extend `HiveObject` to add useful methods to the objects you want to store
/// in Hive
mixin HiveObjectMixin {
  BoxBase? _box;

  dynamic _key;

  // HiveLists containing this object
  final _hiveLists = <HiveList, int>{};

  /// Get the box in which this object is stored. Returns `null` if object has
  /// not been added to a box yet.
  BoxBase? get box => _box;

  /// Get the key associated with this object. Returns `null` if object has
  /// not been added to a box yet.
  dynamic get key => _key;

  void _requireInitialized() {
    if (_box == null) {
      throw HiveError('This object is currently not in a box.');
    }
  }

  /// Persists this object.
  Future<void> save() {
    _requireInitialized();
    return _box!.put(_key, this);
  }

  /// Deletes this object from the box it is stored in.
  Future<void> delete() {
    _requireInitialized();
    return _box!.delete(_key);
  }

  /// Returns whether this object is currently stored in a box.
  ///
  /// For lazy boxes this only checks if the key exists in the box and NOT
  /// whether this instance is actually stored in the box.
  bool get isInBox {
    if (_box != null) {
      if (_box!.lazy) {
        return _box!.containsKey(_key);
      } else {
        return true;
      }
    }
    return false;
  }
}

abstract class HiveObject with HiveObjectMixin {}
