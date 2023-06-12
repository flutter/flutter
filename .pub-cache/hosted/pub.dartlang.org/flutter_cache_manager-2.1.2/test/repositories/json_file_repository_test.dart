import 'dart:io' as io;

import 'package:flutter_cache_manager/src/storage/cache_info_repositories/json_cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/json_repo_helpers.dart';

void main() {
  group('Create repository', () {
    test('Create repository with databasename is successful', () {
      var repository = JsonCacheInfoRepository(databaseName: databaseName);
      expect(repository, isNotNull);
    });

    test('Create repository with path is successful', () {
      var repository = JsonCacheInfoRepository(path: path);
      expect(repository, isNotNull);
    });

    test('Create repository with path and databaseName throws assertion error',
        () {
      expect(
          () => JsonCacheInfoRepository(
                path: path,
                databaseName: databaseName,
              ),
          throwsAssertionError);
    });

    test('Create repository with directory is successful', () {
      var repository = JsonCacheInfoRepository.withFile(io.File(path));
      expect(repository, isNotNull);
    });

    test('Create repository without file throws assertion error', () {
      expect(
          // ignore: missing_required_param
          () => JsonCacheInfoRepository.withFile(null),
          throwsAssertionError);
    });
  });

  group('Open and close repository', () {
    test('Open repository should not throw', () async {
      var repository = JsonCacheInfoRepository.withFile(io.File(path));
      await repository.open();
    });

    test('An open repository can be closed', () async {
      var repository = await JsonRepoHelpers.createRepository();
      var isClosed = await repository.close();
      expect(isClosed, true);
    });

    test('Opening twice should close after second close', () async {
      var repository = await JsonRepoHelpers.createRepository();
      await repository.open();
      var isClosed = await repository.close();
      expect(isClosed, false);
      isClosed = await repository.close();
      expect(isClosed, true);
    });
  });

  group('Exist and delete', () {
    test('New repository does not exist', () async {
      var repository = JsonCacheInfoRepository.withFile(io.File(path));
      var exists = await repository.exists();
      expect(exists, false);
    });

    test('Existing repository does exists', () async {
      var repository = await JsonRepoHelpers.createRepository();
      var exists = await repository.exists();
      expect(exists, true);
    });

    test('Deleted repository does not exists', () async {
      var repository = await JsonRepoHelpers.createRepository();
      await repository.deleteDataFile();
      var exists = await repository.exists();
      expect(exists, false);
    });
  });

  group('Get', () {
    test('Existing key should return', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var result = await repo.get(testurl);
      expect(result, isNotNull);
    });

    test('Non-existing key should return null', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var result = await repo.get('not an url');
      expect(result, isNull);
    });

    test('getAllObjects should return all objects', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var result = await repo.getAllObjects();
      expect(result.length, JsonRepoHelpers.startCacheObjects.length);
    });

    test('getObjectsOverCapacity should return oldest objects', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var result = await repo.getObjectsOverCapacity(1);
      expect(result.length, 2);
      expectIdInList(result, 1);
      expectIdInList(result, 3);
    });

    test('getOldObjects should return only old objects', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var result = await repo.getOldObjects(const Duration(days: 7));
      expect(result.length, 1);
    });
  });

  group('update and insert', () {
    test('insert adds new object', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var objectToInsert = JsonRepoHelpers.extraCacheObject;
      var insertedObject = await repo.insert(JsonRepoHelpers.extraCacheObject);
      expect(insertedObject.id, JsonRepoHelpers.startCacheObjects.length + 1);
      expect(insertedObject.url, objectToInsert.url);
      expect(insertedObject.touched, isNotNull);

      var allObjects = await repo.getAllObjects();
      var newObject =
          allObjects.where((element) => element.id == insertedObject.id);
      expect(newObject, isNotNull);
    });

    test('insert throws when adding existing object', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var objectToInsert = JsonRepoHelpers.startCacheObjects.first;
      expect(() => repo.insert(objectToInsert), throwsArgumentError);
    });

    test('update changes existing item', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var objectToInsert = JsonRepoHelpers.startCacheObjects.first;
      var newUrl = 'newUrl.com';
      var updatedObject = objectToInsert.copyWith(url: newUrl);
      await repo.update(updatedObject);
      var retrievedObject = await repo.get(objectToInsert.key);
      expect(retrievedObject.url, newUrl);
    });

    test('update throws when adding new object', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var newObject = JsonRepoHelpers.extraCacheObject;
      expect(() => repo.update(newObject), throwsArgumentError);
    });

    test('updateOrInsert updates existing item', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var objectToInsert = JsonRepoHelpers.startCacheObjects.first;
      var newUrl = 'newUrl.com';
      var updatedObject = objectToInsert.copyWith(url: newUrl);
      await repo.updateOrInsert(updatedObject);
      var retrievedObject = await repo.get(objectToInsert.key);
      expect(retrievedObject.url, newUrl);
    });

    test('updateOrInsert inserts new item', () async {
      var repo = await JsonRepoHelpers.createRepository();
      var objectToInsert = JsonRepoHelpers.extraCacheObject;
      var insertedObject =
          await repo.updateOrInsert(JsonRepoHelpers.extraCacheObject);
      expect(insertedObject.id, JsonRepoHelpers.startCacheObjects.length + 1);
      expect(insertedObject.url, objectToInsert.url);
      expect(insertedObject.touched, isNotNull);

      var allObjects = await repo.getAllObjects();
      var newObject =
          allObjects.where((element) => element.id == insertedObject.id);
      expect(newObject, isNotNull);
    });
  });

  group('delete', () {
    test('delete removes item', () async {
      var removedId = 2;
      var repo = await JsonRepoHelpers.createRepository();
      var deleted = await repo.delete(removedId);
      expect(deleted, 1);
      var objects = await repo.getAllObjects();
      var removedObject = objects.where((element) => element.id == removedId);
      expect(removedObject.length, 0);
      expect(objects.length, JsonRepoHelpers.startCacheObjects.length - 1);
    });

    test('deleteAll removes all items', () async {
      var removedIds = [2, 3];
      var repo = await JsonRepoHelpers.createRepository();
      var deleted = await repo.deleteAll(removedIds);
      expect(deleted, 2);
      var objects = await repo.getAllObjects();
      var removedObject =
          objects.where((element) => removedIds.contains(element.id));
      expect(removedObject.length, 0);
      expect(objects.length,
          JsonRepoHelpers.startCacheObjects.length - removedIds.length);
    });

    test('delete does not remove non-existing items', () async {
      var removedId = 99;
      var repo = await JsonRepoHelpers.createRepository();
      var deleted = await repo.delete(removedId);
      expect(deleted, 0);
    });
  });

  group('storage', () {
    test('Changes should be persisted', () async {
      var repo = await JsonRepoHelpers.createRepository();
      await repo.insert(JsonRepoHelpers.extraCacheObject);
      var allObjects = await repo.getAllObjects();
      expect(allObjects.length, JsonRepoHelpers.startCacheObjects.length + 1);

      await repo.close();
      await repo.open();

      var allObjectsAfterOpen = await repo.getAllObjects();
      expect(allObjectsAfterOpen.length,
          JsonRepoHelpers.startCacheObjects.length + 1);
    });
  });
}

void expectIdInList(List<CacheObject> cacheObjects, int id) {
  var object = cacheObjects.singleWhere((element) => element.id == id,
      orElse: () => null);
  expect(object, isNotNull);
}
