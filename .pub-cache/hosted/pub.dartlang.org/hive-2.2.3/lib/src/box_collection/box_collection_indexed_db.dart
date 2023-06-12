import 'dart:html';
import 'dart:indexed_db';

import 'package:hive/hive.dart';
import 'package:hive/src/box_collection/box_collection_stub.dart'
    as implementation;

/// represents a [BoxCollection] for raw use with indexed DB
class BoxCollection implements implementation.BoxCollection {
  final Database _db;
  @override
  final Set<String> boxNames;

  BoxCollection(this._db, this.boxNames);

  static Future<BoxCollection> open(
    String name,
    Set<String> boxNames, {
    dynamic path,
    HiveCipher? key,
  }) async {
    final factory = window.indexedDB;
    if (factory == null) {
      throw Exception(
          'Unable to open FluffyBox collection - IndexedDB not supported in this browser!');
    }
    final _db = await factory.open(name, version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
      final _db = event.target.result;
      for (final name in boxNames) {
        _db.createObjectStore(name, autoIncrement: true);
      }
    });
    return BoxCollection(_db, boxNames);
  }

  @override
  String get name => _db.name!;

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
    final box = boxCreator?.call(name, this) as CollectionBox<V>? ??
        CollectionBox<V>(name, this);
    if (preload) {
      box._cache.addAll(await box.getAllValues());
    }
    _openBoxes.add(box);
    return box;
  }

  final List<CollectionBox> _openBoxes = [];

  List<Future<void> Function(Transaction txn)>? _txnCache;

  @override
  Future<void> transaction(
    Future<void> Function() action, {
    List<String>? boxNames,
    bool readOnly = false,
  }) async {
    boxNames ??= this.boxNames.toList();
    if (_txnCache != null) {
      await action();
      return;
    }
    _txnCache = [];
    await action();
    final cache =
        List<Future<void> Function(Transaction txn)>.from(_txnCache ?? []);
    _txnCache = null;
    if (cache.isEmpty) return;
    final txn = _db.transaction(boxNames, readOnly ? 'readonly' : 'readwrite');
    for (final fun in cache) {
      fun(txn);
    }
    await txn.completed;
    return;
  }

  @override
  void close() => _db.close();

  @override
  Future<void> deleteFromDisk() async {
    final factory = window.indexedDB;
    for (final box in _openBoxes) {
      box._cache.clear();
      box._cachedKeys = null;
    }
    _openBoxes.clear();
    _db.close();
    if (factory == null || _db.name == null) {
      throw Exception('Unable to delete fluffybox collection');
    }
    factory.deleteDatabase(_db.name!);
  }
}

class CollectionBox<V> implements implementation.CollectionBox<V> {
  @override
  final String name;
  @override
  final BoxCollection boxCollection;
  final Map<String, V?> _cache = {};
  Set<String>? _cachedKeys;

  CollectionBox(this.name, this.boxCollection) {
    if (!(V is String ||
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
  Future<List<String>> getAllKeys([Transaction? txn]) async {
    final cachedKey = _cachedKeys;
    if (cachedKey != null) return cachedKey.toList();
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    final request = store.getAllKeys(null);
    await request.onSuccess.first;
    final List<String> keys =
        List.from(request.result.cast<String>() as Iterable);
    _cachedKeys = keys.toSet();
    return keys;
  }

  @override
  Future<Map<String, V>> getAllValues([Transaction? txn]) async {
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    final map = <String, V>{};
    final cursorStream = store.openCursor(autoAdvance: true);
    await for (final cursor in cursorStream) {
      map[cursor.key as String] = cursor.value as V;
    }
    return map;
  }

  @override
  Future<V?> get(String key, [Transaction? txn]) async {
    if (_cache.containsKey(key)) return _cache[key];
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    _cache[key] = await store.getObject(key) as V?;
    return _cache[key];
  }

  @override
  Future<List<V?>> getAll(List<String> keys, [Transaction? txn]) async {
    if (!keys.any((key) => !_cache.containsKey(key))) {
      return keys.map((key) => _cache[key]).toList();
    }
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    final list = await Future.wait(keys.map(store.getObject));
    for (var i = 0; i < keys.length; i++) {
      _cache[keys[i]] = list[i] as V?;
    }
    return list.cast<V?>();
  }

  @override
  Future<void> put(String key, V val, [Object? transaction]) async {
    Transaction? txn;
    if (transaction is Transaction) {
      txn = transaction;
    }
    if (val == null) {
      return delete(key, txn);
    }
    final txnCache = boxCollection._txnCache;
    if (txnCache != null) {
      txnCache.add((txn) => put(key, val, txn));
      _cache[key] = val;
      _cachedKeys?.add(key);
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    await store.put(val, key);
    _cache[key] = val;
    _cachedKeys?.add(key);
    return;
  }

  @override
  Future<void> delete(String key, [Transaction? txn]) async {
    final txnCache = boxCollection._txnCache;
    if (txnCache != null) {
      txnCache.add((txn) => delete(key, txn));
      _cache[key] = null;
      _cachedKeys?.remove(key);
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    await store.delete(key);
    _cache[key] = null;
    _cachedKeys?.remove(key);
    return;
  }

  @override
  Future<void> deleteAll(List<String> keys, [Transaction? txn]) async {
    final txnCache = boxCollection._txnCache;
    if (txnCache != null) {
      txnCache.add((txn) => deleteAll(keys, txn));
      for (var key in keys) {
        _cache[key] = null;
      }
      _cachedKeys?.removeAll(keys);
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    for (final key in keys) {
      await store.delete(key);
      _cache[key] = null;
      _cachedKeys?.removeAll(keys);
    }
    return;
  }

  @override
  Future<void> clear([Transaction? txn]) async {
    final txnCache = boxCollection._txnCache;
    if (txnCache != null) {
      txnCache.add(clear);
      _cache.clear();
      _cachedKeys = null;
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    await store.clear();
    _cache.clear();
    _cachedKeys = null;
    return;
  }

  @override
  Future<void> flush() => Future.value();
}
