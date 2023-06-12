import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'cache_info_repository.dart';
import 'helper_methods.dart';

class JsonCacheInfoRepository extends CacheInfoRepository
    with CacheInfoRepositoryHelperMethods {
  Directory? directory;
  String? path;
  String? databaseName;

  /// Either the path or the database name should be provided.
  /// If the path is provider it should end with '{databaseName}.json',
  /// for example: /data/user/0/com.example.example/databases/imageCache.json
  JsonCacheInfoRepository({this.path, this.databaseName})
      : assert(path == null || databaseName == null);

  /// The directory and the databaseName should both the provided. The database
  /// is stored as {databaseName}.json in the directory,
  JsonCacheInfoRepository.withFile(File file) : _file = file;

  File? _file;
  final Map<String, CacheObject> _cacheObjects = {};
  final Map<int, Map<String, dynamic>> _jsonCache = {};

  @override
  Future<bool> open() async {
    if (!shouldOpenOnNewConnection()) {
      return openCompleter!.future;
    }
    var file = await _getFile();
    await _readFile(file);
    return opened();
  }

  @override
  Future<CacheObject?> get(String key) async {
    return _cacheObjects.values.firstWhereOrNull(
      (element) => element.key == key,
    );
  }

  @override
  Future<List<CacheObject>> getAllObjects() async {
    return _cacheObjects.values.toList();
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    if (cacheObject.id != null) {
      throw ArgumentError("Inserted objects shouldn't have an existing id.");
    }
    var keys = _jsonCache.keys;
    var lastId = keys.isEmpty ? 0 : keys.reduce(max);
    var id = lastId + 1;

    cacheObject = cacheObject.copyWith(id: id);
    return _put(cacheObject, setTouchedToNow);
  }

  @override
  Future<int> update(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    if (cacheObject.id == null) {
      throw ArgumentError('Updated objects should have an existing id.');
    }
    _put(cacheObject, setTouchedToNow);
    return 1;
  }

  @override
  Future updateOrInsert(CacheObject cacheObject) {
    return cacheObject.id == null ? insert(cacheObject) : update(cacheObject);
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    var allSorted = _cacheObjects.values.toList()
      ..sort((c1, c2) => c1.touched!.compareTo(c2.touched!));
    if (allSorted.length <= capacity) return [];
    return allSorted.getRange(0, allSorted.length - capacity).toList();
  }

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async {
    var oldestTimestamp = DateTime.now().subtract(maxAge);
    return _cacheObjects.values
        .where(
          (element) => element.touched!.isBefore(oldestTimestamp),
        )
        .toList();
  }

  @override
  Future<int> delete(int id) async {
    var cacheObject = _cacheObjects.values.firstWhereOrNull(
      (element) => element.id == id,
    );
    if (cacheObject == null) {
      return 0;
    }
    _remove(cacheObject);
    return 1;
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) async {
    var deleted = 0;
    for (var id in ids) {
      deleted += await delete(id);
    }
    return deleted;
  }

  @override
  Future<bool> close() async {
    if (!shouldClose()) {
      return false;
    }
    await _saveFile();
    return true;
  }

  Future _readFile(File file) async {
    _cacheObjects.clear();
    _jsonCache.clear();
    if (await file.exists()) {
      try {
        var jsonString = await file.readAsString();
        var json = jsonDecode(jsonString) as List<dynamic>;
        for (var element in json) {
          if (element is! Map<String, dynamic>) continue;
          var map = element;
          var cacheObject = CacheObject.fromMap(map);
          _jsonCache[cacheObject.id!] = map;
          _cacheObjects[cacheObject.key] = cacheObject;
        }
      } catch (e, stacktrace) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: e,
          stack: stacktrace,
          library: 'flutter cache manager',
          context: ErrorDescription('Thrown when reading the file containing '
              'cache info. The cached files cannot be used by the cache manager'
              'anymore.'),
        ));
      }
    }
  }

  CacheObject _put(CacheObject cacheObject, bool setTouchedToNow) {
    final map = cacheObject.toMap(setTouchedToNow: setTouchedToNow);
    _jsonCache[cacheObject.id!] = map;
    var updatedCacheObject = CacheObject.fromMap(map);
    _cacheObjects[cacheObject.key] = updatedCacheObject;
    _cacheUpdated();
    return updatedCacheObject;
  }

  void _remove(CacheObject cacheObject) {
    _cacheObjects.remove(cacheObject.key);
    _jsonCache.remove(cacheObject.id);
    _cacheUpdated();
  }

  void _cacheUpdated() {
    timer?.cancel();
    timer = Timer(timerDuration, _saveFile);
  }

  Timer? timer;
  Duration timerDuration = const Duration(seconds: 3);

  Future _saveFile() async {
    timer?.cancel();
    timer = null;
    await _file!.writeAsString(jsonEncode(_jsonCache.values.toList()));
  }

  @override
  Future deleteDataFile() async {
    var file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists() async {
    var file = await _getFile();
    return file.exists();
  }

  Future<File> _getFile() async {
    if (_file == null) {
      if (path != null) {
        directory = File(path!).parent;
      } else {
        directory ??= await getApplicationSupportDirectory();
      }
      await directory!.create(recursive: true);
      if (path == null || !path!.endsWith('.json')) {
        path = join(directory!.path, '$databaseName.json');
      }
      _file = File(path!);
    }
    return _file!;
  }
}
