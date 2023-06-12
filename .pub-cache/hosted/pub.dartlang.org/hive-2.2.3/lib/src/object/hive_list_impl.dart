import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/object/hive_collection_mixin.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:hive/src/util/delegating_list_view_mixin.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class HiveListImpl<E extends HiveObjectMixin>
    with HiveCollectionMixin<E>, ListMixin<E>, DelegatingListViewMixin<E>
    implements HiveList<E> {
  /// Not part of public API
  final String boxName;

  final List<dynamic>? _keys;

  HiveInterface _hive = Hive;

  List<E>? _delegate;

  Box? _box;

  bool _invalidated = false;

  bool _disposed = false;

  /// Not part of public API
  HiveListImpl(Box box, {List<E>? objects})
      : boxName = box.name,
        _keys = null,
        _delegate = [],
        _box = box {
    if (objects != null) {
      addAll(objects);
    }
  }

  /// Not part of public API
  HiveListImpl.lazy(this.boxName, List<dynamic>? keys) : _keys = keys;

  @override
  Iterable<dynamic> get keys {
    if (_delegate == null) {
      return _keys!;
    } else {
      return super.keys;
    }
  }

  @override
  Box get box {
    if (_box == null) {
      var box = (_hive as HiveImpl).getBoxWithoutCheckInternal(boxName);
      if (box == null) {
        throw HiveError(
            'To use this list, you have to open the box "$boxName" first.');
      } else if (box is! Box) {
        throw HiveError('The box "$boxName" is a lazy box. '
            'You can only use HiveLists with normal boxes.');
      } else {
        _box = box;
      }
    }
    return _box!;
  }

  @override
  List<E> get delegate {
    if (_disposed) {
      throw HiveError('HiveList has already been disposed.');
    }

    if (_invalidated) {
      var retained = <E>[];
      for (var obj in _delegate!) {
        if (obj.isInHiveList(this)) {
          retained.add(obj);
        }
      }
      _delegate = retained;
      _invalidated = false;
    } else if (_delegate == null) {
      var list = <E>[];
      for (var key in _keys!) {
        if (box.containsKey(key)) {
          var obj = box.get(key) as E;
          obj.linkHiveList(this);
          list.add(obj);
        }
      }
      _delegate = list;
    }

    return _delegate!;
  }

  @override
  void dispose() {
    if (_delegate != null) {
      for (var element in _delegate!) {
        element.unlinkHiveList(this);
      }
      _delegate = null;
    }

    _disposed = true;
  }

  /// Not part of public API
  void invalidate() {
    if (_delegate != null) {
      _invalidated = true;
    }
  }

  void _checkElementIsValid(E obj) {
    if (obj.box != box) {
      throw HiveError('HiveObjects needs to be in the box "$boxName".');
    }
  }

  @override
  set length(int newLength) {
    if (newLength < delegate.length) {
      for (var i = newLength; i < delegate.length; i++) {
        delegate[i].unlinkHiveList(this);
      }
    }
    delegate.length = newLength;
  }

  @override
  void operator []=(int index, E value) {
    _checkElementIsValid(value);
    value.linkHiveList(this);

    var oldValue = delegate[index];
    delegate[index] = value;

    oldValue.unlinkHiveList(this);
  }

  @override
  void add(E element) {
    _checkElementIsValid(element);
    element.linkHiveList(this);
    delegate.add(element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (var element in iterable) {
      _checkElementIsValid(element);
      element.linkHiveList(this);
    }
    delegate.addAll(iterable);
  }

  @override
  HiveList<T> castHiveList<T extends HiveObjectMixin>() {
    if (_delegate != null) {
      return HiveListImpl(box, objects: _delegate!.cast());
    } else {
      return HiveListImpl.lazy(boxName, _keys);
    }
  }

  /// Not part of public API
  @visibleForTesting
  set debugHive(HiveInterface hive) => _hive = hive;
}
