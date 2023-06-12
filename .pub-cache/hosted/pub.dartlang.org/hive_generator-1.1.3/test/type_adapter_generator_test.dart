import 'package:hive_generator/src/type_adapter_generator.dart';
import 'package:test/test.dart';

void main() {
  group('generateName', () {
    test('.generateName()', () {
      expect(TypeAdapterGenerator.generateName(r'_$User'), 'UserAdapter');
      expect(TypeAdapterGenerator.generateName(r'_$_SomeClass'),
          'SomeClassAdapter');
    });
  });
}
