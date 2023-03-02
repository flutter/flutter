// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library js_promise;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

import '../util.dart';

@JS()
@staticInterop
class PromiseResolver<T extends Object?> {}

extension PromiseResolverExtension<T extends Object?> on PromiseResolver<T> {
  void resolve(T result) => js_util.callMethod(this, 'call', <Object>[this, if (result != null) result]);
}

@JS()
@staticInterop
class PromiseRejecter {}

extension PromiseRejecterExtension on PromiseRejecter {
  void reject(Object? error) => js_util.callMethod(this, 'call', <Object>[this, if (error != null) error]);
}

/// Type-safe JS Promises
@JS('Promise')
@staticInterop
abstract class Promise<T extends Object?> {
  /// A constructor for a JS promise
  external factory Promise(PromiseExecutor<T> executor);
}

/// The type of function that is used to create a Promise<T>
typedef PromiseExecutor<T extends Object?> = void Function(PromiseResolver<T> resolve, PromiseRejecter reject);

Promise<T> futureToPromise<T extends Object>(Future<T> future) {
  return Promise<T>(allowInterop((PromiseResolver<T> resolver, PromiseRejecter rejecter) {
    future.then(
      (T value) => resolver.resolve(value),
      onError: (Object? error) {
        printWarning('Rejecting promise with error: $error');
        rejecter.reject(error);
      });
  }));
}
