import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../utils.dart';

Stream<int> _getStream() {
  final controller = StreamController<int>();

  Timer(const Duration(milliseconds: 100), () => controller.add(1));
  Timer(const Duration(milliseconds: 200), () => controller.add(2));
  Timer(const Duration(milliseconds: 300), () => controller.add(3));
  Timer(const Duration(milliseconds: 400), () {
    controller.add(4);
    controller.close();
  });

  return controller.stream;
}

void main() {
  test('Rx.ignoreElements', () async {
    var hasReceivedEvent = false;

    _getStream().ignoreElements().listen((_) {
      hasReceivedEvent = true;
    },
        onDone: expectAsync0(() {
          expect(hasReceivedEvent, isFalse);
        }, count: 1));

    expect(
      _getStream().ignoreElements(),
      emitsInOrder(<Object>[emitsDone]),
    );
  });

  test('Rx.ignoreElements.cast', () {
    final ignored = _getStream().ignoreElements();

    expect(ignored, isA<Stream<void>>());
    expect(ignored, isA<Stream<Null>>()); // ignore: prefer_void_to_null
    expect(ignored, isA<Stream<int>>());
    expect(ignored, isA<Stream<int?>>());
    expect(ignored, isA<Stream<Object>>());
    expect(ignored, isA<Stream<Object?>>());

    ignored as Stream<void>; // ignore: unnecessary_cast
    ignored as Stream<Null>; // ignore: unnecessary_cast, prefer_void_to_null
    ignored as Stream<int>; // ignore: unnecessary_cast
    ignored as Stream<int?>; // ignore: unnecessary_cast
    ignored as Stream<Object>; // ignore: unnecessary_cast
    ignored as Stream<Object?>; // ignore: unnecessary_cast

    expect(true, true);
  });

  test('Rx.ignoreElements.reusable', () async {
    final transformer = IgnoreElementsStreamTransformer<int>();
    var hasReceivedEvent = false;

    _getStream().transform(transformer).listen((_) {
      hasReceivedEvent = true;
    },
        onDone: expectAsync0(() {
          expect(hasReceivedEvent, isFalse);
        }, count: 1));

    _getStream().transform(transformer).listen((_) {
      hasReceivedEvent = true;
    },
        onDone: expectAsync0(() {
          expect(hasReceivedEvent, isFalse);
        }, count: 1));
  });

  test('Rx.ignoreElements.asBroadcastStream', () async {
    final stream = _getStream().asBroadcastStream().ignoreElements();

    // listen twice on same stream
    stream.listen(null);
    stream.listen(null);
    // code should reach here
    await expectLater(true, true);
  });

  test('Rx.ignoreElements.pause.resume', () async {
    var hasReceivedEvent = false;

    _getStream().ignoreElements().listen((_) {
      hasReceivedEvent = true;
    },
        onDone: expectAsync0(() {
          expect(hasReceivedEvent, isFalse);
        }, count: 1))
      ..pause()
      ..resume();
  });

  test('Rx.ignoreElements.error.shouldThrow', () async {
    final streamWithError = Stream<void>.error(Exception()).ignoreElements();

    streamWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
          expect(e, isException);
        }, count: 1));
  });

  test('Rx.ignoreElements accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.ignoreElements();

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });

  test('Rx.ignoreElements.nullable', () {
    nullableTest<Never>(
      (s) => s.ignoreElements(),
    );
  });
}
