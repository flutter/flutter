@TestOn('vm')

import 'package:hive/src/backend/vm/backend_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  group('BackendManager', () {
    group('findHiveFileAndCleanUp', () {
      Future<void> checkFindHiveFileAndCleanUp(String folder) async {
        var hiveFileDir =
            await getAssetDir('findHiveFileAndCleanUp', folder, 'before');
        var hiveFile = await BackendManager()
            .findHiveFileAndCleanUp('testBox', hiveFileDir.path);
        expect(hiveFile.path, path.join(hiveFileDir.path, 'testBox.hive'));
        await expectDirEqualsAssetDir(
            hiveFileDir, 'findHiveFileAndCleanUp', folder, 'after');
      }

      test('no hive file', () async {
        await checkFindHiveFileAndCleanUp('no_hive_file');
      });

      test('hive file', () async {
        await checkFindHiveFileAndCleanUp('hive_file');
      });

      test('hive file and compact file', () async {
        await checkFindHiveFileAndCleanUp('hive_file_and_compact_file');
      });

      test('only compact file', () async {
        await checkFindHiveFileAndCleanUp('only_compact_file');
      });
    });
  });
}
