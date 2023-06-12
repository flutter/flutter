import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('Rx.timeout', () async {
    StreamSubscription<int> subscription;

    final stream = Stream<int>.fromFuture(
            Future<int>.delayed(Duration(milliseconds: 30), () => 1))
        .timeout(Duration(milliseconds: 1));

    subscription = stream.listen((_) {},
        onError: expectAsync2((TimeoutException e, StackTrace s) {
          expect(e is TimeoutException, isTrue);
          subscription.cancel();
        }, count: 1));
  });
}
