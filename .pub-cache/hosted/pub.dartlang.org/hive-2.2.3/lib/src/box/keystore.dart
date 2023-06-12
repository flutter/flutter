// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:hive/src/util/indexable_skip_list.dart';
import 'package:meta/meta.dart';

import 'box_base_impl.dart';

/// Not part of public API
class KeyTransaction<E> {
  /// The values that have been added
  final List<dynamic> added = [];

  /// The frames that have been deleted
  final Map<dynamic, Frame> deleted = HashMap();

  /// Not part of public API
  @visibleForTesting
  KeyTransaction();
}

/// Not part of public API
class Keystore<E> {
  final BoxBase<E> _box;

  final ChangeNotifier _notifier;

  final IndexableSkipList<dynamic, Frame> _store;

  /// Not part of public API
  @visibleForTesting
  final ListQueue<KeyTransaction<E>> transactions = ListQueue();

  var _deletedEntries = 0;
  var _autoIncrement = -1;

  /// Not part of public API
  Keystore(this._box, this._notifier, KeyComparator? keyComparator)
      : _store = IndexableSkipList(keyComparator ?? defaultKeyComparator);

  /// Not part of public API
  factory Keystore.debug({
    Iterable<Frame> frames = const [],
    BoxBase<E>? box,
    ChangeNotifier? notifier,
    KeyComparator keyComparator = defaultKeyComparator,
  }) {
    var keystore = Keystore<E>(box ?? BoxBaseImpl.nullImpl<E>(),
        notifier ?? ChangeNotifier(), keyComparator);
    for (var frame in frames) {
      keystore.insert(frame);
    }
    return keystore;
  }

  /// Not part of public API
  int get deletedEntries => _deletedEntries;

  /// Not part of public API
  int get length => _store.length;

  /// Not part of public API
  Iterable<Frame> get frames => _store.values;

  /// Not part of public API
  void resetDeletedEntries() {
    _deletedEntries = 0;
  }

  /// Not part of public API
  int autoIncrement() {
    return ++_autoIncrement;
  }

  /// Not part of public API
  void updateAutoIncrement(int key) {
    if (key > _autoIncrement) {
      _autoIncrement = key;
    }
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool containsKey(dynamic key) {
    return _store.get(key) != null;
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  dynamic keyAt(int index) {
    return _store.getKeyAt(index);
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Frame? get(dynamic key) {
    return _store.get(key);
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Frame? getAt(int index) {
    return _store.getAt(index);
  }

  /// Not part of public API
  Iterable<dynamic> getKeys() {
    return _store.keys;
  }

  /// Not part of public API
  Iterable<E> getValues() {
    return _store.values.map((e) => e.value as E);
  }

  /// Not part of public API
  Iterable<E> getValuesBetween([dynamic startKey, dynamic endKey]) sync* {
    Iterable<Frame> iterable;
    if (startKey != null) {
      iterable = _store.valuesFromKey(startKey);
    } else {
      iterable = _store.values;
    }

    for (var frame in iterable) {
      yield frame.value as E;

      if (frame.key == endKey) break;
    }
  }

  /// Not part of public API
  Stream<BoxEvent> watch({dynamic key}) {
    return _notifier.watch(key: key);
  }

  /// Not part of public API
  Frame? insert(Frame frame, {bool notify = true, bool lazy = false}) {
    var value = frame.value;
    Frame? deletedFrame;

    if (!frame.deleted) {
      var key = frame.key;
      if (key is int && key > _autoIncrement) {
        _autoIncrement = key;
      }

      if (value is HiveObjectMixin) {
        value.init(key, _box);
      }

      deletedFrame = _store.insert(key, lazy ? frame.toLazy() : frame);
    } else {
      deletedFrame = _store.delete(frame.key);
    }

    if (deletedFrame != null) {
      _deletedEntries++;
      if (deletedFrame.value is HiveObjectMixin &&
          !identical(deletedFrame.value, value)) {
        (deletedFrame.value as HiveObjectMixin).dispose();
      }
    }

    if (notify && (!frame.deleted || deletedFrame != null)) {
      _notifier.notify(frame);
    }

    return deletedFrame;
  }

  /// Not part of public API
  bool beginTransaction(List<Frame> newFrames) {
    var transaction = KeyTransaction<E>();
    for (var frame in newFrames) {
      if (!frame.deleted) {
        transaction.added.add(frame.key);
      }

      var deletedFrame = insert(frame);
      if (deletedFrame != null) {
        transaction.deleted[frame.key] = deletedFrame;
      }
    }

    if (transaction.added.isNotEmpty || transaction.deleted.isNotEmpty) {
      transactions.add(transaction);
      return true;
    } else {
      return false;
    }
  }

  /// Not part of public API
  void commitTransaction() {
    transactions.removeFirst();
  }

  /// Not part of public API
  void cancelTransaction() {
    var canceled = transactions.removeFirst();

    deleted_loop:
    for (var key in canceled.deleted.keys) {
      var deletedFrame = canceled.deleted[key];
      for (var t in transactions) {
        if (t.deleted.containsKey(key)) {
          t.deleted[key] = deletedFrame!;
          continue deleted_loop;
        }
        if (t.added.contains(key)) {
          t.deleted[key] = deletedFrame!;
          continue deleted_loop;
        }
      }

      _store.insert(key, deletedFrame);
      _notifier.notify(deletedFrame!);
    }

    added_loop:
    for (var key in canceled.added) {
      var isOverride = canceled.deleted.containsKey(key);
      for (var t in transactions) {
        if (t.deleted.containsKey(key)) {
          if (!isOverride) {
            t.deleted.remove(key);
          }
          continue added_loop;
        }
        if (t.added.contains(key)) {
          continue added_loop;
        }
      }
      if (!isOverride) {
        _store.delete(key);
        _notifier.notify(Frame.deleted(key));
      }
    }
  }

  /// Not part of public API
  int clear() {
    var frameList = frames.toList();

    _store.clear();

    for (var frame in frameList) {
      if (frame.value is HiveObjectMixin) {
        (frame.value as HiveObjectMixin).dispose();
      }
      _notifier.notify(Frame.deleted(frame.key));
    }

    _deletedEntries = 0;
    _autoIncrement = -1;
    return frameList.length;
  }

  /// Not part of public API
  Future close() {
    return _notifier.close();
  }
}
