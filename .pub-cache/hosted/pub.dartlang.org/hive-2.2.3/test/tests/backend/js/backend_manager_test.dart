@TestOn('browser')
import 'dart:html';
import 'dart:indexed_db';

import 'package:hive/src/backend/js/backend_manager.dart';
import 'package:test/test.dart';

Future<Database> _openDb() async {
  return await window.indexedDB!.open('testBox', version: 1,
      onUpgradeNeeded: (e) {
    var db = e.target.result as Database;
    if (!db.objectStoreNames!.contains('box')) {
      db.createObjectStore('box');
    }
  });
}

void main() {
  group('BackendManager', () {
    group('.boxExists()', () {
      test('returns true', () async {
        var backendManager = BackendManager.select();
        var db = await _openDb();
        db.close();
        expect(await backendManager.boxExists('testBox', null, null), isTrue);
      });

      test('returns false', () async {
        var backendManager = BackendManager.select();
        var boxName = 'notexists-${DateTime.now().millisecondsSinceEpoch}';
        expect(await backendManager.boxExists(boxName, null, null), isFalse);
      });
    });
  });
}
