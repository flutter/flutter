// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Mock class to control the return result of Live Text input functions.
class LiveTextInputTester {

  LiveTextInputTester() {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, _handler);
  }

  bool mockLiveTextInputEnabled = false;

  Future<Object?> _handler(MethodCall methodCall) async {
    // Need to set Clipboard.hasStrings method handler because when showing the tool bar,
    // the Clipboard.hasStrings will also be invoked. If we doesn't handle this,
    // an exception will be thrown.
    if (methodCall.method == 'Clipboard.hasStrings') {
      return <String, bool>{'value': true};
    }
    if (methodCall.method == 'LiveText.isLiveTextInputAvailable') {
      return mockLiveTextInputEnabled;
    }
    return false;
  }

  void dispose() {
    assert(TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.checkMockMessageHandler(SystemChannels.platform.name, _handler));
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  }
}
