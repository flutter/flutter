import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('Rx.join', () async {
    final joined = await Stream.fromIterable(const ['h', 'i']).join('+');

    await expectLater(joined, 'h+i');
  });
}
