import 'dart:async';
import 'package:hive/hive.dart';

abstract class BoxCollection {
  String get name;
  Set<String> get boxNames;

  static Future<BoxCollection> open(
    String name,
    Set<String> boxNames, {
    String? path,
    HiveCipher? key,
  }) {
    throw UnimplementedError();
  }

  Future<CollectionBox<V>> openBox<V>(String name,
      {bool preload = false,
      CollectionBox<V> Function(String, BoxCollection)? boxCreator});

  Future<void> transaction(
    Future<void> Function() action, {
    List<String>? boxNames,
    bool readOnly = false,
  });

  void close();

  Future<void> deleteFromDisk();
}

/// represents a [Box] being part of a [BoxCollection]
abstract class CollectionBox<V> {
  String get name;
  BoxCollection get boxCollection;

  Future<List<String>> getAllKeys();

  Future<Map<String, V>> getAllValues();

  Future<V?> get(String key);

  Future<List<V?>> getAll(
    List<String> keys,
  );

  Future<void> put(String key, V val, [Object? transaction]);

  Future<void> delete(String key);

  Future<void> deleteAll(List<String> keys);

  Future<void> clear();

  Future<void> flush();
}
