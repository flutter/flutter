import 'package:hive/src/adapters/ignored_type_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('IgnoredTypeAdapter', () {
    test('.read()', () {
      var binaryReader = MockBinaryReader();
      var value = IgnoredTypeAdapter().read(binaryReader);
      verifyNever(() => binaryReader.read());
      expect(value, null);
    });

    test('.write()', () {
      var binaryWriter = MockBinaryWriter();
      IgnoredTypeAdapter().write(binaryWriter, 42);
      verifyNever(() => binaryWriter.writeInt(42));
    });
  });
}
