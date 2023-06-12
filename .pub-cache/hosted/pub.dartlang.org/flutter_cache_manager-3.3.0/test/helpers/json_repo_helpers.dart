import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';

const String databaseName = 'test';
const String path =
    '/data/user/0/com.example.example/databases/$databaseName.json';
final directory = MemoryFileSystem().directory('database');
const String testurl = 'www.baseflow.com/test.png';
const String testurl2 = 'www.baseflow.com/test2.png';
const String testurl3 = 'www.baseflow.com/test3.png';
const String testurl4 = 'www.baseflow.com/test4.png';

class JsonRepoHelpers {
  static Future<JsonCacheInfoRepository> createRepository(
      {bool open = true}) async {
    var directory = await _createDirectory();
    var file = await _createFile(directory);
    var repository = JsonCacheInfoRepository.withFile(file);
    if (open) await repository.open();
    return repository;
  }

  static Future<Directory> _createDirectory() async {
    var testDir =
        await MemoryFileSystem().systemTempDirectory.createTemp('testFolder');
    await testDir.create(recursive: true);
    return testDir;
  }

  static Future<File> _createFile(Directory dir) {
    var file = dir.childFile('$databaseName.json');
    var json = jsonEncode(_createCacheObjects());
    return file.writeAsString(json);
  }

  static List<Map<String, dynamic>> _createCacheObjects() {
    return startCacheObjects
        .map((e) => e.toMap(setTouchedToNow: false))
        .toList();
  }

  static final defaultValidTill = clock.now().add(const Duration(days: 7));
  static final defaultRelativePath = 'test.png';
  static final List<CacheObject> startCacheObjects = [
    // Old object
    CacheObject(
      testurl,
      key: testurl,
      id: 1,
      touched: clock.now().subtract(const Duration(days: 8)),
      validTill: defaultValidTill,
      relativePath: defaultRelativePath,
    ),
    // New object
    CacheObject(
      testurl2,
      key: testurl2,
      id: 2,
      touched: clock.now(),
      validTill: defaultValidTill,
      relativePath: defaultRelativePath,
    ),
    // A less new object
    CacheObject(
      testurl3,
      key: testurl3,
      id: 3,
      touched: clock.now().subtract(const Duration(minutes: 1)),
      validTill: defaultValidTill,
      relativePath: defaultRelativePath,
    ),
  ];
  static final CacheObject extraCacheObject = CacheObject(
    testurl4,
    key: testurl4,
    validTill: defaultValidTill,
    relativePath: defaultRelativePath,
  );
}
