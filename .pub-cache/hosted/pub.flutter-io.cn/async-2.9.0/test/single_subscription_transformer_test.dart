// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test("buffers events as soon as it's bound", () async {
    var controller = StreamController.broadcast();
    var stream =
        controller.stream.transform(const SingleSubscriptionTransformer());

    // Add events before [stream] has a listener to be sure it buffers them.
    controller.add(1);
    controller.add(2);
    await flushMicrotasks();

    expect(stream.toList(), completion(equals([1, 2, 3, 4])));
    await flushMicrotasks();

    controller.add(3);
    controller.add(4);
    controller.close();
  });

  test("cancels the subscription to the broadcast stream when it's canceled",
      () async {
    var canceled = false;
    var controller = StreamController.broadcast(onCancel: () {
      canceled = true;
    });
    var stream =
        controller.stream.transform(const SingleSubscriptionTransformer());
    await flushMicrotasks();
    expect(canceled, isFalse);

    var subscription = stream.listen(null);
    await flushMicrotasks();
    expect(canceled, isFalse);

    subscription.cancel();
    await flushMicrotasks();
    expect(canceled, isTrue);
  });
}
