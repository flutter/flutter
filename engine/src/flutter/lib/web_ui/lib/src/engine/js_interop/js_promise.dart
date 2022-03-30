// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library js_promise;

import 'package:js/js.dart';

/// Type-safe JS Promises
@JS('Promise')
abstract class Promise<T> {
  /// A constructor for a JS promise
  external factory Promise(PromiseExecutor<T> executor);
}

/// The type of function that is used to create a Promise<T>
typedef PromiseExecutor<T> = void Function(PromiseResolver<T> resolve, PromiseRejecter reject);
/// The type of function used to resolve a Promise<T>
typedef PromiseResolver<T> = void Function(T result);
/// The type of function used to reject a Promise (of any <T>)
typedef PromiseRejecter = void Function(Object? error);
