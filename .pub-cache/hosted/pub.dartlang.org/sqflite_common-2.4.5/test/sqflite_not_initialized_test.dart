import 'package:sqflite_common/sqflite.dart';
import 'package:test/test.dart';

void main() {
  test('basic', () async {
    await expectLater(
        () => openDatabase(inMemoryDatabasePath), throwsA(isA<StateError>()));
  });
}
