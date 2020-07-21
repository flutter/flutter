// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/driver_extension.dart';

/// Wraps a flutter driver [DataHandler] with one that waits until a delegate is set.
///
/// This allows the driver test to call [FlutterDriver.requestData] before the handler was
/// set by the app in which case the requestData call will only complete once the app is ready
/// for it.
class FutureDataHandler {
  Map<String, Completer<Function()>> _handlers = <String, Completer<Function()>>{};

  /// Registers a lazy handler that will be invoked on the next message from the driver.
  Completer<Function()> registerHandler(String key) {
    _handlers[key] = Completer<Function()>();
    return _handlers[key];
  }

  Future<String> handleMessage(String message) async {
    if (_handlers[message] == null) {
      return 'Unsupported driver message: $message.\n'
             'Supported messages are: ${_handlers.keys}.';
    }
    final Function() handler = await _handlers[message].future;
    return handler();
  }
}

FutureDataHandler driverDataHandler = FutureDataHandler();