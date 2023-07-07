// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

@JS()
library firebase_interop.core.es6;

import 'package:js/js.dart';

import 'func.dart';

@JS('Promise')
class PromiseJsImpl<T> {
  external PromiseJsImpl(Function resolver);
  external PromiseJsImpl then([Func1? onResolve, Func1? onReject]);
}
