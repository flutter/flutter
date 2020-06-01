// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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

@pragma('vm:entry-point')
Handle _viewRef;

class MxStartupInfo {
  // TODO: refactor Handle to a Channel
  // https://github.com/flutter/flutter/issues/49439
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
  // https://github.com/flutter/flutter/issues/49439
  static Handle takeOutgoingServices() {
    if (_outgoingServices == null && Platform.isFuchsia) {
      throw Exception(
          'Attempting to call takeOutgoingServices more than once per process');
    }
    Handle handle = _outgoingServices;
    _outgoingServices = null;
    return handle;
  }

  // TODO: refactor Handle to a ViewRef
  // https://github.com/flutter/flutter/issues/49439
  static Handle takeViewRef() {
    if (_viewRef == null && Platform.isFuchsia) {
      throw Exception(
          'Attempting to call takeViewRef more than once per process');
    }
    Handle handle = _viewRef;
    _viewRef = null;
    return handle;
  }
}

void _setReturnCode(int returnCode) native 'SetReturnCode';

void exit(int returnCode) {
  _setReturnCode(returnCode);
  Isolate.current.kill(priority: Isolate.immediate);
}
