// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_util';

@JS('fetch')
external JSPromise<_JSResponse> __fetch(JSString url);

Future<_JSResponse> _fetch(String url) {
  return promiseToFuture<_JSResponse>(__fetch(url.toJS));
}

extension type _JSResponse(JSObject _) implements JSObject {}

/// Returns [true] if the bytes at [url] can be fetched.
///
/// The bytes may be unable to be fetched if they aren't from the same origin
/// and the sever hosting them does not allow cross-origin requests.
Future<bool> checkIfImageBytesCanBeFetched(String url) {
  return _fetch(url).then((_JSResponse response) {
    return true;
  }).catchError((_) {
    return false;
  });
}
