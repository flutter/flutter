// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

/// Returns a single-subscription stream that emits the results of [operations]
/// in the order they complete.
///
/// If the subscription is canceled, any pending operations are canceled as
/// well.
Stream<T> inCompletionOrder<T>(Iterable<CancelableOperation<T>> operations) {
  var operationSet = operations.toSet();
  var controller = StreamController<T>(
      sync: true,
      onCancel: () =>
          Future.wait(operationSet.map((operation) => operation.cancel())));

  for (var operation in operationSet) {
    operation.value
        .then((value) => controller.add(value))
        .onError(controller.addError)
        .whenComplete(() {
      operationSet.remove(operation);
      if (operationSet.isEmpty) controller.close();
    });
  }

  return controller.stream;
}

void unawaited(Future<void> f) {}
