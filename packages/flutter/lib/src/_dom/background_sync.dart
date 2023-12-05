// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'service_workers.dart';

@JS('SyncManager')
@staticInterop
class SyncManager {}

extension SyncManagerExtension on SyncManager {
  external JSPromise register(String tag);
  external JSPromise getTags();
}

@JS('SyncEvent')
@staticInterop
class SyncEvent implements ExtendableEvent {
  external factory SyncEvent(
    String type,
    SyncEventInit init,
  );
}

extension SyncEventExtension on SyncEvent {
  external String get tag;
  external bool get lastChance;
}

@JS()
@staticInterop
@anonymous
class SyncEventInit implements ExtendableEventInit {
  external factory SyncEventInit({
    required String tag,
    bool lastChance,
  });
}

extension SyncEventInitExtension on SyncEventInit {
  external set tag(String value);
  external String get tag;
  external set lastChance(bool value);
  external bool get lastChance;
}
