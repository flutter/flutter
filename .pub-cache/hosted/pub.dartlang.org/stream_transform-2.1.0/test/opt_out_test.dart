// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:async';

import 'package:async/async.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  group('null returned from StreamSubscription.cancel', () {
    void testNullCancel(
        String name, Stream<void> Function(Stream<void>) transform) {
      test(name, () async {
        var subscription = transform(_NullOnCancelStream()).listen(null);
        await subscription.cancel();
      });
    }

    testNullCancel('asyncMapSample', (s) => s.asyncMapSample((_) async {}));
    testNullCancel('buffer', (s) => s.buffer(_nonEndingStream()));
    testNullCancel(
        'combineLatestAll', (s) => s.combineLatestAll([_NullOnCancelStream()]));
    testNullCancel('combineLatest',
        (s) => s.combineLatest(_NullOnCancelStream(), (a, b) {}));
    testNullCancel('merge', (s) => s.merge(_NullOnCancelStream()));

    test('switchLatest', () async {
      var subscription =
          _NullOnCancelStream(Stream<Stream<void>>.value(_NullOnCancelStream()))
              .switchLatest()
              .listen(null);
      await Future(() {});
      await subscription.cancel();
    });

    test('concurrentAsyncExpand', () async {
      var subscription = _NullOnCancelStream(Stream.value(null))
          .concurrentAsyncExpand((_) => _NullOnCancelStream())
          .listen(null);
      await Future(() {});
      await subscription.cancel();
    });
  });
}

class _NullOnCancelStream<T> extends StreamView<T> {
  _NullOnCancelStream([Stream<T> stream]) : super(stream ?? _nonEndingStream());

  @override
  StreamSubscription<T> listen(void Function(T) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      _NullOnCancelSubscription(super.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError));
}

class _NullOnCancelSubscription<T> extends DelegatingStreamSubscription<T> {
  final StreamSubscription<T> _subscription;
  _NullOnCancelSubscription(this._subscription) : super(_subscription);

  @override
  Future<void> cancel() {
    _subscription.cancel();
    return null;
  }
}

Stream<T> _nonEndingStream<T>() => StreamController<T>().stream;
