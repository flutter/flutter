@TestOn('vm')
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:test/test.dart';

void main() {
  test("is native", () {
    expect(Platform.instance.platform, isNot(equals("web")));
    expect(Platform.instance.isNative, equals(true));
    expect(Platform.instance.fullWidthInteger, equals(true));
  });

  test('width assertion', () {
    expect(() => {Platform.instance.assertFullWidthInteger()}, returnsNormally);
  });
}
