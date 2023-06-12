import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import 'box_collection_stub.dart' as implementation;

class BoxCollection implements implementation.BoxCollection {
  @override
  final String name;
  @override
  final Set<String> boxNames;
  HiveCipher? _cipher;

  BoxCollection(this.name, this.boxNames);

  static bool _hiveInit = false;

  late Box<String> _badKeyBox;

  static Future<BoxCollection> open(
    String name,
    Set<String> boxNames, {
    String? path,
    HiveCipher? key,
  }) async {
    if (!_hiveInit) {
      Hive.init(path ?? './');
      _hiveInit = true;
    }
    final collection = BoxCollection(name, boxNames);
    if (key != null) {
      collection._cipher = key;
    }
    collection._badKeyBox = await Hive.openBox<String>('${name}_bad_keys');

    return collection;
  }

  @override
  Future<CollectionBox<V>> openBox<V>(String name,
      {bool preload = false,
      implementation.CollectionBox<V> Function(String, BoxCollection)?
          boxCreator}) async {
    if (!boxNames.contains(name)) {
      throw Exception(
          'Box with name $name is not in the known box names of this collection.');
    }
    final i = _openBoxes.indexWhere((box) => box.name == name);
    if (i != -1) {
      return _openBoxes[i] as CollectionBox<V>;
    }
    final boxIdentifier = '${this.name}_$name';
    final box = boxCreator?.call(boxIdentifier, this) as CollectionBox<V>? ??
        CollectionBox<V>(boxIdentifier, this);
    if (preload) {
      box._cachedBox = await Hive.openBox(
        box.name,
        encryptionCipher: _cipher,
        collection: name,
      );
    }
    _openBoxes.add(box);
    return box;
  }

  final List<CollectionBox> _openBoxes = [];

  @override
  Future<void> transaction(
    Future<void> Function() action, {
    List<String>? boxNames,
    bool readOnly = false,
  }) async {
    await runZoned(() async {
      try {
        CollectionBox.transactionBoxes[Zone.current] = <String>{};
        await action();
      } finally {
        final flushFutures = <Future<void>>[];
        for (final boxName in CollectionBox.transactionBoxes[Zone.current]!) {
          final i = _openBoxes.indexWhere((box) => box.name == boxName);
          if (i != -1) {
            flushFutures.add(_openBoxes[i].flush());
          }
        }
        await Future.wait(flushFutures);
        CollectionBox.transactionBoxes.remove(Zone.current);
      }
    });
  }

  @override
  void close() {
    for (final box in _openBoxes) {
      box._cachedBox?.close();
    }
  }

  @override
  Future<void> deleteFromDisk() => Future.wait(
        boxNames.map(Hive.deleteBoxFromDisk),
      );
}

/// represents a [Box] being part of a [BoxCollection]
class CollectionBox<V> implements implementation.CollectionBox<V> {
  @override
  final String name;
  @override
  final BoxCollection boxCollection;

  static final transactionBoxes = <Zone, Set<String>>{};

  BoxBase? _cachedBox;

  Future<BoxBase> _getBox() async {
    return _cachedBox ??= await Hive.openLazyBox<V>(
      name,
      encryptionCipher: boxCollection._cipher,
      collection: boxCollection.name,
    );
  }

  CollectionBox(this.name, this.boxCollection) {
    if (!(V is String ||
        V is bool ||
        V is int ||
        V is Object ||
        V is List<Object?> ||
        V is Map<String, Object?> ||
        V is double)) {
      throw Exception(
          'Value type ${V.runtimeType} is not one of the allowed value types {String, int, double, List<Object?>, Map<String, Object?>}.');
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    final box = await _getBox();
    return box.keys
        .cast<String>()
        .map((key) {
          if (key.startsWith(_badKeyPrefix)) {
            key = boxCollection._badKeyBox.get(key) ?? key;
          }
          return key;
        })
        .map(Uri.decodeComponent)
        .toList();
  }

  @override
  Future<Map<String, V>> getAllValues() async {
    final box = await _getBox();
    final keys = box.keys.toList();
    if (box is LazyBox) {
      final values = await Future.wait(keys.map(box.get));
      return {
        for (var i = 0; i < values.length; i++)
          Uri.decodeComponent(keys[i] as String): values[i] as V
      };
    }
    return (box as Box)
        .toMap()
        .map((k, v) => MapEntry(Uri.decodeComponent(k.toString()), v as V));
  }

  @override
  Future<V?> get(String key) async {
    key = _toHiveKey(key);
    final box = await _getBox();
    if (box is LazyBox) return await box.get(key) as V?;
    return (box as Box).get(key) as V?;
  }

  @override
  Future<List<V?>> getAll(
    List<String> keys,
  ) async {
    final box = await _getBox();
    final values = <V?>[];
    for (var key in keys) {
      key = _toHiveKey(key);
      if (box is LazyBox) {
        values.add(await box.get(key) as V?);
      } else {
        values.add((box as Box).get(key) as V?);
      }
    }
    return values;
  }

  @override
  Future<void> put(String key, V val, [Object? transaction]) async {
    if (val == null) {
      return delete(key);
    }
    final box = await _getBox();
    await box.put(_toHiveKey(key), val);
    await _flushOrMark();
  }

  @override
  Future<void> delete(String key) async {
    final box = await _getBox();
    await box.delete(_toHiveKey(key));
    await _flushOrMark();
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    final hiveKeys = keys.map(_toHiveKey);
    final box = await _getBox();
    await box.deleteAll(hiveKeys);
    await _flushOrMark();
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.deleteAll(box.keys);
    await _flushOrMark();
  }

  @override
  Future<void> flush() async {
    final box = await _getBox();
    // we do *not* await the flushing here. That makes it so that we can execute
    // other stuff while the flusing is still in progress. Fortunately, hive has
    // a proper read / write queue, meaning that if we do actually want to write
    // something again, it'll wait until the flush is completed.
    box.flush();
  }

  Future<void> _flushOrMark() async {
    final zone = _getTransactionZone();
    if (zone == null) {
      await flush();
    } else {
      transactionBoxes[zone]!.add(name);
    }
  }

  Zone? _getTransactionZone([Zone? testZone]) {
    testZone ??= Zone.current;
    if (testZone == Zone.root) {
      return null;
    }
    if (transactionBoxes.keys.contains(testZone)) {
      return testZone;
    }
    return _getTransactionZone(testZone.parent);
  }

  static const int _maxKeyLength = 255;
  static const String _badKeyPrefix = '_bad_key_';

  String _calcHashKey(String encodedKey) =>
      _badKeyPrefix + sha256.convert(utf8.encode(encodedKey)).toString();

  String _toHiveKey(String key) {
    final encodedKey = key.split('|').map(Uri.encodeComponent).join('|');
    if (encodedKey.length >= _maxKeyLength) {
      final hashKey = _calcHashKey(encodedKey);
      boxCollection._badKeyBox.put(hashKey, encodedKey);
      return hashKey;
    }
    return encodedKey;
  }
}
