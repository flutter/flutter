// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/driver_extension.dart';

typedef DriverHandler = Future<String> Function();

/// Wraps a flutter driver [DataHandler] with one that waits until a delegate is set.
///
/// This allows the driver test to call [FlutterDriver.requestData] before the handler was
/// set by the app in which case the requestData call will only complete once the app is ready
/// for it.
class FutureDataHandler {
  final Map<String, Completer<DriverHandler>> _handlers = <String, Completer<DriverHandler>>{};

  /// Registers a lazy handler that will be invoked on the next message from the driver.
  Completer<DriverHandler> registerHandler(String key) {
    final Completer<DriverHandler>? existing = _handlers[key];
    if (existing != null && !existing.isCompleted) {
      return existing;
    }
    final completer = Completer<DriverHandler>();
    _handlers[key] = completer;
    return completer;
  }

  Future<String> handleMessage(String? message) async {
    if (message == null) {
      return 'Unsupported driver message: null';
    }
    final Completer<DriverHandler> completer = _handlers.putIfAbsent(
      message,
      () => Completer<DriverHandler>(),
    );
    final DriverHandler handler = await completer.future;
    return handler();
  }
}

FutureDataHandler driverDataHandler = FutureDataHandler();
