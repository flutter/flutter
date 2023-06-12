import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/object/hive_object.dart';

/// Not part of public API
class BoxImpl<E> extends BoxBaseImpl<E> implements Box<E> {
  /// Not part of public API
  BoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator? keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
  ) : super(hive, name, keyComparator, compactionStrategy, backend);

  @override
  final bool lazy = false;

  @override
  Iterable<E> get values {
    checkOpen();

    return keystore.getValues();
  }

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) {
    checkOpen();

    return keystore.getValuesBetween(startKey, endKey);
  }

  @override
  E? get(dynamic key, {E? defaultValue}) {
    checkOpen();

    var frame = keystore.get(key);
    if (frame != null) {
      return frame.value as E?;
    } else {
      if (defaultValue != null && defaultValue is HiveObjectMixin) {
        defaultValue.init(key, this);
      }
      return defaultValue;
    }
  }

  @override
  E? getAt(int index) {
    checkOpen();

    return keystore.getAt(index)?.value as E?;
  }

  @override
  Future<void> putAll(Map<dynamic, E> kvPairs) {
    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
    }

    return _writeFrames(frames);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) {
    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    return _writeFrames(frames);
  }

  Future<void> _writeFrames(List<Frame> frames) async {
    checkOpen();

    if (!keystore.beginTransaction(frames)) return;

    try {
      await backend.writeFrames(frames);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var frame in keystore.frames) {
      map[frame.key] = frame.value as E;
    }
    return map;
  }

  @override
  Future<void> flush() async {
    await backend.flush();
  }
}
