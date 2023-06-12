import 'package:flutter_cache_manager/src/storage/cache_object.dart';

import 'cache_info_repository.dart';

class NonStoringObjectProvider implements CacheInfoRepository {
  @override
  Future<bool> close() async {
    return true;
  }

  @override
  Future<int> delete(int id) {
    return Future.value(1);
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) {
    return Future.value(ids.length);
  }

  @override
  Future<CacheObject?> get(String url) {
    return Future.value(null);
  }

  @override
  Future<List<CacheObject>> getAllObjects() {
    return Future.value([]);
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) {
    return Future.value([]);
  }

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) {
    return Future.value([]);
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) {
    return Future.value(cacheObject);
  }

  @override
  Future<bool> open() async {
    return true;
  }

  @override
  Future<int> update(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) {
    return Future.value(0);
  }

  @override
  Future updateOrInsert(CacheObject cacheObject) {
    return Future.value();
  }

  @override
  Future<void> deleteDataFile() async {
    return;
  }

  @override
  Future<bool> exists() async {
    return false;
  }
}
