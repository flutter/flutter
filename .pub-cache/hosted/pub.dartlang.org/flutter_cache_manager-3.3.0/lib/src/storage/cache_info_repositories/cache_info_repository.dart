import 'dart:async';

import 'package:flutter_cache_manager/src/logger.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';

/// Base class for cache info repositories
abstract class CacheInfoRepository {
  /// Returns whether or not there is an existing data file with cache info.
  Future<bool> exists();

  /// Opens the repository, or just returns true if the repo is already open.
  Future<bool> open();

  /// Updates a given [CacheObject], if it exists, or adds a new item to the repository
  Future<dynamic> updateOrInsert(CacheObject cacheObject);

  /// Inserts [cacheObject] into the repository
  Future<CacheObject> insert(CacheObject cacheObject,
      {bool setTouchedToNow = true});

  /// Gets a [CacheObject] by [key]
  Future<CacheObject?> get(String key);

  /// Deletes a cache object by [id]
  Future<int> delete(int id);

  /// Deletes items with [ids] from the repository
  Future<int> deleteAll(Iterable<int> ids);

  /// Updates an existing [cacheObject]
  Future<int> update(CacheObject cacheObject, {bool setTouchedToNow = true});

  /// Gets the list of all objects in the cache
  Future<List<CacheObject>> getAllObjects();

  /// Gets the list of [CacheObject] that can be removed if the repository is over capacity.
  ///
  /// The exact implementation is up to the repository, but implementations should
  /// return a preferred list of items. For example, the least recently accessed
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity);

  /// Returns a list of [CacheObject] that are older than [maxAge]
  Future<List<CacheObject>> getOldObjects(Duration maxAge);

  /// Close the connection to the repository. If this is the last connection
  /// to the repository it will return true and the repository is trully
  /// closed. If there are still open connections it will return false;
  Future<bool> close();

  /// Deletes the cache data file including all cache data.
  Future<void> deleteDataFile();
}

extension MigrationExtension on CacheInfoRepository {
  Future<void> migrateFrom(CacheInfoRepository previousRepository) async {
    if (!await previousRepository.exists()) return;

    await previousRepository.open();
    var cacheObjects = await previousRepository.getAllObjects();
    await _putAll(cacheObjects);
    var isClosed = await previousRepository.close();
    if (!isClosed) {
      cacheLogger.log('Deleting an open repository while migrating.',
          CacheManagerLogLevel.warning);
    }
    await previousRepository.deleteDataFile();
  }

  Future<List<CacheObject>> _putAll(List<CacheObject> cacheObjects) async {
    var storedObjects = <CacheObject>[];
    for (var newObject in cacheObjects) {
      var existingObject = await get(newObject.key);
      final CacheObject storedObject;
      if (existingObject == null) {
        storedObject = await insert(
          newObject.copyWith(id: null),
          setTouchedToNow: false,
        );
      } else {
        storedObject = newObject.copyWith(id: existingObject.id);
        await update(storedObject, setTouchedToNow: false);
      }
      storedObjects.add(storedObject);
    }
    return storedObjects;
  }
}
