import 'package:link_hook/link_hook.dart';
import 'package:test/test.dart';

void main() {
  test('invoke native function', () {
    // Tests are run in debug mode.
    expect(difference(24, 18), 24 - 18);
  });
}
