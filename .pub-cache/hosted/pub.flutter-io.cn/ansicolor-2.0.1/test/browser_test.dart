import 'package:ansicolor/ansicolor.dart';
import 'package:test/test.dart';

@TestOn('browser')
void main() {
  setUp(() {
    ansiColorDisabled = false;
  });

  tearDown(() {
    ansiColorDisabled = false;
  });
  test('browser compiles', () {
    expect(ansiColorDisabled, isFalse);
  });
}
