// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';

typedef LockGrantedCallback = JSFunction;
typedef LockMode = String;

@JS('LockManager')
@staticInterop
class LockManager {}

extension LockManagerExtension on LockManager {
  external JSPromise request(
    String name,
    JSObject callbackOrOptions, [
    LockGrantedCallback callback,
  ]);
  external JSPromise query();
}

@JS()
@staticInterop
@anonymous
class LockOptions {
  external factory LockOptions({
    LockMode mode,
    bool ifAvailable,
    bool steal,
    AbortSignal signal,
  });
}

extension LockOptionsExtension on LockOptions {
  external set mode(LockMode value);
  external LockMode get mode;
  external set ifAvailable(bool value);
  external bool get ifAvailable;
  external set steal(bool value);
  external bool get steal;
  external set signal(AbortSignal value);
  external AbortSignal get signal;
}

@JS()
@staticInterop
@anonymous
class LockManagerSnapshot {
  external factory LockManagerSnapshot({
    JSArray held,
    JSArray pending,
  });
}

extension LockManagerSnapshotExtension on LockManagerSnapshot {
  external set held(JSArray value);
  external JSArray get held;
  external set pending(JSArray value);
  external JSArray get pending;
}

@JS()
@staticInterop
@anonymous
class LockInfo {
  external factory LockInfo({
    String name,
    LockMode mode,
    String clientId,
  });
}

extension LockInfoExtension on LockInfo {
  external set name(String value);
  external String get name;
  external set mode(LockMode value);
  external LockMode get mode;
  external set clientId(String value);
  external String get clientId;
}

@JS('Lock')
@staticInterop
class Lock {}

extension LockExtension on Lock {
  external String get name;
  external LockMode get mode;
}
