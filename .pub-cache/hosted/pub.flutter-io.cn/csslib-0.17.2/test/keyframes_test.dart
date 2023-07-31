import 'package:csslib/src/messages.dart';
import 'package:test/test.dart';

import 'testing.dart';

void main() {
  test('keyframes', () {
    final input =
        r'@keyframes ping { 75%, 100% { transform: scale(2); opacity: 0; } }';
    var errors = <Message>[];
    var stylesheet = compileCss(input, errors: errors, opts: options);
    expect(errors, isEmpty);
    final expected = r'''
@keyframes ping {
  75%, 100% {
  transform: scale(2);
  opacity: 0;
  }
}''';
    expect(prettyPrint(stylesheet), expected);
  });
}
