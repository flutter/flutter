import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:js' as js;
import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/native/storage_backend_js.dart';
import 'package:hive/src/backend/storage_backend.dart';

/// Opens IndexedDB databases
class BackendManager implements BackendManagerInterface {
  IdbFactory? get indexedDB => js.context.hasProperty('window')
      ? window.indexedDB
      : WorkerGlobalScope.instance.indexedDB;

  @override
  Future<StorageBackend> open(String name, String? path, bool crashRecovery,
      HiveCipher? cipher, String? collection) async {
    // compatibility for old store format
    final databaseName = collection ?? name;
    final objectStoreName = collection == null ? 'box' : name;

    var db =
        await indexedDB!.open(databaseName, version: 1, onUpgradeNeeded: (e) {
      var db = e.target.result as Database;
      if (!(db.objectStoreNames ?? []).contains(objectStoreName)) {
        db.createObjectStore(objectStoreName);
      }
    });

    // in case the objectStore is not contained, re-open the db and
    // update version
    if (!(db.objectStoreNames ?? []).contains(objectStoreName)) {
      print(
          'Creating objectStore $objectStoreName in database $databaseName...');
      db = await indexedDB!.open(
        databaseName,
        version: (db.version ?? 1) + 1,
        onUpgradeNeeded: (e) {
          var db = e.target.result as Database;
          if (!(db.objectStoreNames ?? []).contains(objectStoreName)) {
            db.createObjectStore(objectStoreName);
          }
        },
      );
    }

    print('Got object store $objectStoreName in database $databaseName.');

    return StorageBackendJs(db, cipher, objectStoreName);
  }

  @override
  Future<void> deleteBox(String name, String? path, String? collection) async {
    print('Delete $name // $collection from disk');

    // compatibility for old store format
    final databaseName = collection ?? name;
    final objectStoreName = collection == null ? 'box' : name;

    // directly deleting the entire DB if a non-collection Box
    if (collection == null) {
      await indexedDB!.deleteDatabase(databaseName);
    } else {
      final db =
          await indexedDB!.open(databaseName, version: 1, onUpgradeNeeded: (e) {
        var db = e.target.result as Database;
        if ((db.objectStoreNames ?? []).contains(objectStoreName)) {
          db.deleteObjectStore(objectStoreName);
        }
      });
      if ((db.objectStoreNames ?? []).isEmpty) {
        indexedDB!.deleteDatabase(databaseName);
      }
    }
  }

  @override
  Future<bool> boxExists(String name, String? path, String? collection) async {
    // compatibility for old store format
    final databaseName = collection ?? name;
    final objectStoreName = collection == null ? 'box' : name;
    // https://stackoverflow.com/a/17473952
    try {
      var _exists = true;
      if (collection == null) {
        await indexedDB!.open(databaseName, version: 1, onUpgradeNeeded: (e) {
          e.target.transaction!.abort();
          _exists = false;
        });
      } else {
        final db =
            await indexedDB!.open(collection, version: 1, onUpgradeNeeded: (e) {
          var db = e.target.result as Database;
          _exists = (db.objectStoreNames ?? []).contains(objectStoreName);
        });
        _exists = (db.objectStoreNames ?? []).contains(objectStoreName);
      }
      return _exists;
    } catch (error) {
      return false;
    }
  }
}
