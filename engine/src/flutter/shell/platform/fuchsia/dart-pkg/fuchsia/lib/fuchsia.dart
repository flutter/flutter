// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fuchsia;

import 'dart:io';
import 'dart:isolate';
import 'dart:zircon';

// ignore_for_file: native_function_body_in_non_sdk_code
// ignore_for_file: public_member_api_docs

// TODO: refactors this incomingServices instead
@pragma('vm:entry-point')
Handle _environment;

@pragma('vm:entry-point')
Handle _outgoingServices;

class MxStartupInfo {
  // TODO: refactor Handle to a Channel
  static Handle takeEnvironment() {
    if (_outgoingServices == null && Platform.isFuchsia) {
      throw Exception(
          'Attempting to call takeEnvironment more than once per process');
    }
    Handle handle = _environment;
    _environment = null;
    return handle;
  }

  // TODO: refactor Handle to a Channel
  static Handle takeOutgoingServices() {
    if (_outgoingServices == null && Platform.isFuchsia) {
      throw Exception(
          'Attempting to call takeOutgoingServices more than once per process');
    }
    Handle handle = _outgoingServices;
    _outgoingServices = null;
    return handle;
  }
}

void _setReturnCode(int returnCode) native 'SetReturnCode';

void exit(int returnCode) {
  _setReturnCode(returnCode);
  Isolate.current.kill(priority: Isolate.immediate);
}
