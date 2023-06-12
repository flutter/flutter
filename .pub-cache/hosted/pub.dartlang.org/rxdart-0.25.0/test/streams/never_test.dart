import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/streams/never.dart';
import 'package:test/test.dart';

void main() {
  test('NeverStream', () async {
    var onDataCalled = false, onDoneCalled = false, onErrorCalled = false;

    final stream = NeverStream<Null>();

    final subscription = stream.listen(
        expectAsync1((_) {
          onDataCalled = true;
        }, count: 0),
        onError: expectAsync2((Exception e, StackTrace s) {
          onErrorCalled = false;
        }, count: 0),
        onDone: expectAsync0(() {
          onDataCalled = true;
        }, count: 0));

    await Future<Null>.delayed(Duration(milliseconds: 10));

    await subscription.cancel();

    // We do not expect onData, onDone, nor onError to be called, as [never]
    // streams emit no items or errors, and they do not terminate
    await expectLater(onDataCalled, isFalse);
    await expectLater(onDoneCalled, isFalse);
    await expectLater(onErrorCalled, isFalse);
  });

  test('NeverStream.single.subscription', () async {
    final stream = NeverStream<Null>();

    stream.listen(null);
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('Rx.never', () async {
    var onDataCalled = false, onDoneCalled = false, onErrorCalled = false;

    final stream = Rx.never<Null>();

    final subscription = stream.listen(
        expectAsync1((_) {
          onDataCalled = true;
        }, count: 0),
        onError: expectAsync2((Exception e, StackTrace s) {
          onErrorCalled = false;
        }, count: 0),
        onDone: expectAsync0(() {
          onDataCalled = true;
        }, count: 0));

    await Future<Null>.delayed(Duration(milliseconds: 10));

    await subscription.cancel();

    // We do not expect onData, onDone, nor onError to be called, as [never]
    // streams emit no items or errors, and they do not terminate
    await expectLater(onDataCalled, isFalse);
    await expectLater(onDoneCalled, isFalse);
    await expectLater(onErrorCalled, isFalse);
  });
}
