// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'hr_time.dart';
import 'indexeddb.dart';
import 'service_workers.dart';

@JS('StorageBucketManager')
@staticInterop
class StorageBucketManager {}

extension StorageBucketManagerExtension on StorageBucketManager {
  external JSPromise open(
    String name, [
    StorageBucketOptions options,
  ]);
  external JSPromise keys();
  external JSPromise delete(String name);
}

@JS()
@staticInterop
@anonymous
class StorageBucketOptions {
  external factory StorageBucketOptions({
    bool persisted,
    int? quota,
    DOMHighResTimeStamp? expires,
  });
}

extension StorageBucketOptionsExtension on StorageBucketOptions {
  external set persisted(bool value);
  external bool get persisted;
  external set quota(int? value);
  external int? get quota;
  external set expires(DOMHighResTimeStamp? value);
  external DOMHighResTimeStamp? get expires;
}

@JS('StorageBucket')
@staticInterop
class StorageBucket {}

extension StorageBucketExtension on StorageBucket {
  external JSPromise persist();
  external JSPromise persisted();
  external JSPromise estimate();
  external JSPromise setExpires(DOMHighResTimeStamp expires);
  external JSPromise expires();
  external JSPromise getDirectory();
  external String get name;
  external IDBFactory get indexedDB;
  external CacheStorage get caches;
}
