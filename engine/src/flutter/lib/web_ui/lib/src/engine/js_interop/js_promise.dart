// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library js_promise;

import 'dart:js_interop';

import 'package:js/js_util.dart' as js_util;

import '../util.dart';

extension CallExtension on JSFunction {
  external void call(JSAny? this_, JSAny? object);
}

@JS('Promise')
external JSAny get _promiseConstructor;

JSPromise<JSAny?> createPromise(JSFunction executor) =>
  js_util.callConstructor(
    _promiseConstructor,
    <Object>[executor],
  );


JSPromise<JSAny?> futureToPromise<T extends JSAny?>(Future<T> future) {
  return createPromise((JSFunction resolver, JSFunction rejecter) {
    future.then(
      (T value) => resolver.call(null, value),
      onError: (Object? error) {
        printWarning('Rejecting promise with error: $error');
        rejecter.call(null, null);
      });
  }.toJS);
}
