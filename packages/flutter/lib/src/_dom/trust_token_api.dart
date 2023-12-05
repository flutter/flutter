// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef RefreshPolicy = String;
typedef TokenVersion = String;
typedef OperationType = String;

@JS()
@staticInterop
@anonymous
class PrivateToken {
  external factory PrivateToken({
    required TokenVersion version,
    required OperationType operation,
    RefreshPolicy refreshPolicy,
    JSArray issuers,
  });
}

extension PrivateTokenExtension on PrivateToken {
  external set version(TokenVersion value);
  external TokenVersion get version;
  external set operation(OperationType value);
  external OperationType get operation;
  external set refreshPolicy(RefreshPolicy value);
  external RefreshPolicy get refreshPolicy;
  external set issuers(JSArray value);
  external JSArray get issuers;
}
