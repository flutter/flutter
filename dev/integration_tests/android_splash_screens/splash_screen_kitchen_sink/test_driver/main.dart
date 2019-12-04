// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter/services.dart';
import 'package:splash_screen_kitchen_sink/main.dart' as app;

Completer<String> dataHandlerCompleter;
final List<String> appToHostMessageQueue = <String>[];

/// How this test works:
/// 1. Android's UI changes as the app starts up.
/// 2. Android sends messages to this Flutter app about those UI changes.
/// 3. This Flutter app forwards those messages from the app to the host
///    machine running the driver test.
/// 4. The driver test evaluates the UI change events to determine if the
///    behavior is expected or unexpected and then passes or fails the test.
void main() {
  enableFlutterDriverExtension(handler: respondToHostRequestForSplashLog);

  createTestChannelBetweenAndroidAndFlutter();

  app.main();
}

Future<String> respondToHostRequestForSplashLog(String _) {
  if (appToHostMessageQueue.isNotEmpty) {
    return Future<String>.value(appToHostMessageQueue.removeAt(0));
  } else {
    dataHandlerCompleter = Completer<String>();
    return dataHandlerCompleter.future;
  }
}

void createTestChannelBetweenAndroidAndFlutter() {
  // Channel used for Android to send Flutter changes to the splash display.
  const BasicMessageChannel<String> testChannel = BasicMessageChannel<String>(
      'testChannel',
      StringCodec(),
  );

  // Every splash display change message that we receive from Android is either
  // immediately sent to the host driver test, or queued up to be sent to the
  // host driver test at the next opportunity.
  testChannel.setMessageHandler((String message) async {
    appToHostMessageQueue.add(message);
    if (dataHandlerCompleter != null) {
      dataHandlerCompleter.complete(appToHostMessageQueue.removeAt(0));
    }
    return '';
  });
}
