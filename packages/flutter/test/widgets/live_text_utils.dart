// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock class to control the return result of Live Text input functions.
class LiveTextInputTester {
  LiveTextInputTester() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, _handler);
  }

  bool mockLiveTextInputEnabled = false;

  Future<Object?> _handler(MethodCall methodCall) async {
    // Need to set Clipboard.hasStrings method handler because when showing the tool bar,
    // the Clipboard.hasStrings will also be invoked. If this isn't handled,
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
    assert(TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.checkMockMessageHandler(SystemChannels.platform.name, _handler));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  }
}

/// A function to find the live text button.
Finder findLiveTextButton() => find.byWidgetPredicate((Widget widget) =>
  widget is CustomPaint &&
  '${widget.painter?.runtimeType}' == '_LiveTextIconPainter',
);
