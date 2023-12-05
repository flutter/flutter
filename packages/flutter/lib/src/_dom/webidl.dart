// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef ArrayBufferView = JSObject;
typedef BufferSource = JSObject;
typedef AllowSharedBufferSource = JSObject;
typedef VoidFunction = JSFunction;

@JS('DOMException')
@staticInterop
class DOMException {
  external factory DOMException([
    String message,
    String name,
  ]);

  external static int get INDEX_SIZE_ERR;
  external static int get DOMSTRING_SIZE_ERR;
  external static int get HIERARCHY_REQUEST_ERR;
  external static int get WRONG_DOCUMENT_ERR;
  external static int get INVALID_CHARACTER_ERR;
  external static int get NO_DATA_ALLOWED_ERR;
  external static int get NO_MODIFICATION_ALLOWED_ERR;
  external static int get NOT_FOUND_ERR;
  external static int get NOT_SUPPORTED_ERR;
  external static int get INUSE_ATTRIBUTE_ERR;
  external static int get INVALID_STATE_ERR;
  external static int get SYNTAX_ERR;
  external static int get INVALID_MODIFICATION_ERR;
  external static int get NAMESPACE_ERR;
  external static int get INVALID_ACCESS_ERR;
  external static int get VALIDATION_ERR;
  external static int get TYPE_MISMATCH_ERR;
  external static int get SECURITY_ERR;
  external static int get NETWORK_ERR;
  external static int get ABORT_ERR;
  external static int get URL_MISMATCH_ERR;
  external static int get QUOTA_EXCEEDED_ERR;
  external static int get TIMEOUT_ERR;
  external static int get INVALID_NODE_TYPE_ERR;
  external static int get DATA_CLONE_ERR;
}

extension DOMExceptionExtension on DOMException {
  external String get name;
  external String get message;
  external int get code;
}
