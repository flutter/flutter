import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const columnId = '_id';
  const columnUrl = 'url';
  const columnKey = 'key';
  const columnPath = 'relativePath';
  const columnETag = 'eTag';
  const columnValidTill = 'validTill';
  const columnTouched = 'touched';

  const validMillis = 1585301160000;
  final validDate = DateTime.utc(2020, 03, 27, 09, 26).toLocal();
  final now = DateTime(2020, 03, 28, 09, 26);

  final testId = 1;
  final relativePath = 'test.png';
  final testUrl = 'www.test.com/image';
  final testKey = 'test123';
  final eTag = 'test1';

  test('constructor, no explicit key', () {
    final object = CacheObject(
      'baseflow.com/test.png',
      relativePath: 'test.png',
      validTill: validDate,
      eTag: 'test1',
      id: 3,
    );
    expect(object.url, 'baseflow.com/test.png');
    expect(object.key, object.url);
  });

  test('constructor, explicit key', () {
    final object = CacheObject(
      'baseflow.com/test.png',
      key: 'test key 1234',
      relativePath: 'test.png',
      validTill: validDate,
      eTag: 'test1',
      id: 3,
    );
    expect(object.url, 'baseflow.com/test.png');
    expect(object.key, 'test key 1234');
  });

  group('Test CacheObject mapping', () {
    test('Test making CacheObject from map, no explicit key', () {
      var map = {
        columnId: 3,
        columnUrl: 'baseflow.com/test.png',
        columnPath: 'test.png',
        columnETag: 'test1',
        columnValidTill: validMillis,
        columnTouched: now.millisecondsSinceEpoch
      };
      var object = CacheObject.fromMap(map);
      expect(object.id, 3);
      expect(object.url, 'baseflow.com/test.png');
      expect(object.key, object.url);
      expect(object.relativePath, 'test.png');
      expect(object.eTag, 'test1');
      expect(object.validTill, validDate);
    });

    test('Test making CacheObject from map, with explicit key', () {
      var map = {
        columnId: 3,
        columnUrl: 'baseflow.com/test.png',
        columnKey: 'testId1234',
        columnPath: 'test.png',
        columnETag: 'test1',
        columnValidTill: validMillis,
        columnTouched: now.millisecondsSinceEpoch
      };
      var object = CacheObject.fromMap(map);
      expect(object.id, 3);
      expect(object.url, 'baseflow.com/test.png');
      expect(object.key, 'testId1234');
      expect(object.relativePath, 'test.png');
      expect(object.eTag, 'test1');
      expect(object.validTill, validDate);
    });

    test('Test encoding CacheObject to map', () async {
      await withClock(Clock.fixed(now), () async {
        var object = CacheObject(
          'baseflow.com/test.png',
          key: 'testKey1234',
          relativePath: 'test.png',
          validTill: validDate,
          eTag: 'test1',
          id: 3,
        );

        var map = object.toMap();
        expect(map[columnId], 3);
        expect(map[columnUrl], 'baseflow.com/test.png');
        expect(map[columnKey], 'testKey1234');
        expect(map[columnPath], 'test.png');
        expect(map[columnETag], 'test1');
        expect(map[columnValidTill], validMillis);
        expect(map[columnTouched], now.millisecondsSinceEpoch);
      });
    });
  });

  group('Test CacheObject copy', () {
    test('copy with id', () {
      var cacheObject = CacheObject(
        testUrl,
        id: null,
        key: testKey,
        relativePath: relativePath,
        validTill: now,
        eTag: eTag,
        length: 200,
      );
      var newObject = cacheObject.copyWith(id: testId);
      expect(newObject.id, testId);
      expect(newObject.url, testUrl);
      expect(newObject.key, testKey);
      expect(newObject.relativePath, relativePath);
      expect(newObject.validTill, now);
      expect(newObject.eTag, eTag);
      expect(newObject.length, 200);
    });

    test('copy with url', () {
      var cacheObject = CacheObject(
        testUrl,
        id: testId,
        key: testKey,
        relativePath: relativePath,
        validTill: now,
        eTag: eTag,
        length: 200,
      );
      const newUrl = 'www.someotherurl.com';
      final newObject = cacheObject.copyWith(url: newUrl);
      expect(newObject.id, testId);
      expect(newObject.url, newUrl);
      expect(newObject.key, testKey);
      expect(newObject.relativePath, relativePath);
      expect(newObject.validTill, now);
      expect(newObject.eTag, eTag);
      expect(newObject.length, 200);
    });

    test('copy with path', () {
      var cacheObject = CacheObject(
        testUrl,
        id: testId,
        key: testKey,
        relativePath: relativePath,
        validTill: now,
        eTag: eTag,
        length: 200,
      );
      var newObject = cacheObject.copyWith(relativePath: 'newPath.jpg');
      expect(newObject.id, testId);
      expect(newObject.url, testUrl);
      expect(newObject.key, testKey);
      expect(newObject.relativePath, 'newPath.jpg');
      expect(newObject.validTill, now);
      expect(newObject.eTag, eTag);
      expect(newObject.length, 200);
    });

    test('copy with validTill', () {
      var cacheObject = CacheObject(
        testUrl,
        id: testId,
        key: testKey,
        relativePath: relativePath,
        validTill: now,
        eTag: eTag,
        length: 200,
      );
      var newObject = cacheObject.copyWith(validTill: validDate);
      expect(newObject.id, testId);
      expect(newObject.url, testUrl);
      expect(newObject.key, testKey);
      expect(newObject.relativePath, relativePath);
      expect(newObject.validTill, validDate);
      expect(newObject.eTag, eTag);
      expect(newObject.length, 200);
    });

    test('copy with eTag', () {
      var cacheObject = CacheObject(
        testUrl,
        id: testId,
        key: testKey,
        relativePath: relativePath,
        validTill: now,
        eTag: eTag,
        length: 200,
      );
      var newObject = cacheObject.copyWith(eTag: 'fileChangedRecently');
      expect(newObject.id, testId);
      expect(newObject.url, testUrl);
      expect(newObject.key, testKey);
      expect(newObject.relativePath, relativePath);
      expect(newObject.validTill, now);
      expect(newObject.eTag, 'fileChangedRecently');
      expect(newObject.length, 200);
    });

    test('copy with length', () {
      var cacheObject = CacheObject(
        testUrl,
        id: testId,
        key: testKey,
        relativePath: relativePath,
        validTill: now,
        eTag: eTag,
        length: 200,
      );
      var newObject = cacheObject.copyWith(length: 300);
      expect(newObject.id, testId);
      expect(newObject.url, testUrl);
      expect(newObject.key, testKey);
      expect(newObject.relativePath, relativePath);
      expect(newObject.validTill, now);
      expect(newObject.eTag, eTag);
      expect(newObject.length, 300);
    });
  });
}
