// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library firebase_mock;

import 'package:js/js.dart';

@JS()
@anonymous
class FirebaseAppOptionsMock {
  // mock with minimum required fields for testing
  external factory FirebaseAppOptionsMock({
    String? apiKey,
    String? appId,
    String? messagingSenderId,
    String? projectId,
  });

  external String get apiKey;

  external String get appId;

  external String get messagingSenderId;

  external String get projectId;
}

@JS()
@anonymous
class FirebaseAppMock {
  external factory FirebaseAppMock({
    String? name,
    FirebaseAppOptionsMock? options,
  });

  external String get name;

  external FirebaseAppOptionsMock get options;
}

@JS()
@anonymous
class FirebaseMock {
  external factory FirebaseMock({Function? app});

  external Function get app;
}

@JS()
class Promise<T> {
  external Promise(
    void Function(void Function(T result) resolve, Function reject) executor,
  );

  external Promise then(
    void Function(T result) onFulfilled, [
    Function? onRejected,
  ]);
}

// Wire to the global 'window.firebase' object.
@JS('firebase_core')
external set firebaseMock(FirebaseMock mock);

@JS('firebase_core')
external FirebaseMock get firebaseMock;
