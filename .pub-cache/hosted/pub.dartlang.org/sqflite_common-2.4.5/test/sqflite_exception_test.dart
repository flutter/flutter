import 'dart:typed_data';

import 'package:sqflite_common/src/exception.dart';
import 'package:test/test.dart';

void main() {
  group('sqflite_exception', () {
    test('isUniqueConstraint', () async {
      // Android
      var msg = 'UNIQUE constraint failed: Test.name (code 2067))';
      var exception = SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isNotNullConstraintError(), isFalse);
      expect(exception.isUniqueConstraintError(), isTrue);
      expect(exception.isUniqueConstraintError('Test.name'), isTrue);

      msg = 'UNIQUE constraint failed: Test.name (code 1555))';
      exception = SqfliteDatabaseException(msg, null);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isTrue);
      expect(exception.isUniqueConstraintError('Test.name'), isTrue);
    });

    test('isNotNullConstraint', () async {
      // FFI mac
      var msg =
          'DatabaseException(SqliteException(1299): NOT NULL constraint failed: Test.name, constraint failed (code 1299))';
      var exception = SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.isUniqueConstraintError('Test.name'), isFalse);
      expect(exception.getResultCode(), 1299);

      // ios
      msg =
          'DatabaseException(Error Domain=FMDatabase Code=1299 "NOT NULL constraint failed: Test.name"';
      exception = SqfliteDatabaseException(msg, null);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isNotNullConstraintError(), isTrue);
      expect(exception.isNotNullConstraintError('Test.name'), isTrue);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.isUniqueConstraintError('Test.name'), isFalse);
      expect(exception.getResultCode(), 1299);
    });

    test('isSyntaxError', () async {
      // Android
      final msg = 'near "DUMMY": syntax error (code 1)';
      final exception = SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isTrue);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.getResultCode(), 1);
    });

    test('isSyntaxError with symbolic names', () {
      // Android
      final msg = 'near "DUMMY": syntax error (code 1 SQLITE_ERROR)';
      final exception = SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isTrue);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.getResultCode(), 1);
    });

    test('isNoSuchTable', () async {
      // Android
      final msg = 'no such table: Test (code 1)';
      final exception = SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isNoSuchTableError(), isTrue);
      expect(exception.isNoSuchTableError('Test'), isTrue);
      expect(exception.isNoSuchTableError('Other'), isFalse);
      expect(exception.isDuplicateColumnError('tableName'), isFalse);
      expect(exception.isDuplicateColumnError(), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.getResultCode(), 1);
    });

    test('isDuplicateColumn', () {
      // Android
      final msg = 'duplicate column name: tableName (code 1 SQLITE_ERROR)';
      final exception = SqfliteDatabaseException(msg, null);
      expect(exception.isDatabaseClosedError(), isFalse);
      expect(exception.isReadOnlyError(), isFalse);
      expect(exception.isDuplicateColumnError('tableName'), isTrue);
      expect(exception.isDuplicateColumnError(), isTrue);
      expect(exception.isDuplicateColumnError('tableName2'), isFalse);
      expect(exception.isNoSuchTableError(), isFalse);
      expect(exception.isNoSuchTableError('Test'), isFalse);
      expect(exception.isNoSuchTableError('Other'), isFalse);
      expect(exception.isOpenFailedError(), isFalse);
      expect(exception.isSyntaxError(), isFalse);
      expect(exception.isUniqueConstraintError(), isFalse);
      expect(exception.getResultCode(), 1);
    });
    test('getResultCode', () async {
      // Android
      final msg = 'UNIQUE constraint failed: Test.name (code 2067))';
      var exception = SqfliteDatabaseException(msg, null);
      expect(exception.getResultCode(), 2067);
      exception = SqfliteDatabaseException(
          'UNIQUE constraint failed: Test.name (code 1555))', null);
      expect(exception.getResultCode(), 1555);
      exception =
          SqfliteDatabaseException('near "DUMMY": syntax error (code 1)', null);
      expect(exception.getResultCode(), 1);

      exception = SqfliteDatabaseException(
          'attempt to write a readonly database (code 8)) running Open read-only',
          null);
      expect(exception.getResultCode(), 8);

      // iOS: Error Domain=FMDatabase Code=19 'UNIQUE constraint failed: Test.name' UserInfo={NSLocalizedDescription=UNIQUE constraint failed: Test.name}) s
      exception = SqfliteDatabaseException(
          "Error Domain=FMDatabase Code=19 'UNIQUE constraint failed: Test.name' UserInfo={NSLocalizedDescription=UNIQUE constraint failed: Test.name})",
          null);
      expect(exception.getResultCode(), 19);
      exception =
          SqfliteDatabaseException('Error Domain=FMDatabase Code=19', null);
      expect(exception.getResultCode(), 19);
    });

    test('Exception args', () async {
      var exception = SqfliteDatabaseException('test', {
        'sql': 'statement',
        'arguments': [
          null,
          1,
          'short',
          '123456789012345678901234567890123456789012345678901',
          Uint8List.fromList([1, 2, 3])
        ]
      });
      expect(exception.toString(),
          'DatabaseException(test) sql \'statement\' args [null, 1, short, 12345678901234567890123456789012345678901234567890..., Blob(3)]');
    });
    test('Exception result', () async {
      DatabaseException exception = SqfliteDatabaseException('test', 1);
      expect(exception.result, 1);
      exception = SqfliteDatabaseException('test', null);
      expect(exception.result, isNull);
    });
  });
}
