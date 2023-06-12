import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('path_utils', () {
    test('inMemory', () {
      // Sounds obvious...
      expect(inMemoryDatabasePath, ':memory:');
      expect(isInMemoryDatabasePath('test.db'), isFalse);
      expect(isInMemoryDatabasePath(':memory:'), isTrue);
      expect(isInMemoryDatabasePath('file::memory:'), isTrue);
    });

    test('fileUri', () {
      expect(isFileUriDatabasePath('file::memory:'), isTrue);
      expect(isFileUriDatabasePath('filememory'), isFalse);
      expect(isFileUriDatabasePath('file:relative'), isTrue);
      expect(isFileUriDatabasePath('file:///abs'), isTrue);
    });
  });
}
