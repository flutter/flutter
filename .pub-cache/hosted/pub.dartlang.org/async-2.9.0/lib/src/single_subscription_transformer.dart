// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A transformer that converts a broadcast stream into a single-subscription
/// stream.
///
/// This buffers the broadcast stream's events, which means that it starts
/// listening to a stream as soon as it's bound.
///
/// This also casts the source stream's events to type `T`. If the cast fails,
/// the result stream will emit a [TypeError]. This behavior is deprecated, and
/// should not be relied upon.
class SingleSubscriptionTransformer<S, T> extends StreamTransformerBase<S, T> {
  const SingleSubscriptionTransformer();

  @override
  Stream<T> bind(Stream<S> stream) {
    late StreamSubscription<S> subscription;
    var controller =
        StreamController<T>(sync: true, onCancel: () => subscription.cancel());
    subscription = stream.listen((value) {
      // TODO(nweiz): When we release a new major version, get rid of the second
      // type parameter and avoid this conversion.
      try {
        controller.add(value as T);
      } on TypeError catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }, onError: controller.addError, onDone: controller.close);
    return controller.stream;
  }
}
