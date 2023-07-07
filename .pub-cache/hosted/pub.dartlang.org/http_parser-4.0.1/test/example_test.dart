import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('validate example', () {
    final result = Process.runSync(
      Platform.executable,
      [
        '--enable-experiment=non-nullable',
        'example/example.dart',
      ],
    );

    expect(result.exitCode, 0);
    expect(result.stdout, '''
2014-09-09 09:09:09.000Z
Tue, 09 Sep 2014 09:09:09 GMT
2014-09-09 09:09:09.000Z
''');
  }, testOn: 'vm');
}
