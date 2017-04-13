// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'widget_tester.dart';

const String _kTextInputClientChannel = 'flutter/textinputclient';

/// A testing stub for the system's onscreen keyboard.
///
/// Typical app tests will not need to use this class directly.
///
/// See also:
///
/// * [WidgetTester.enterText], which uses this class to simulate keyboard input.
/// * [WidgetTester.showKeyboard], which uses this class to simulate showing the
///   popup keyboard and initializing its text.
class TestTextInput {
  void register() {
    SystemChannels.textInput.setMockMethodCallHandler(handleTextInputCall);
  }

  int _client = 0;
  Map<String, dynamic> editingState;

  Future<dynamic> handleTextInputCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'TextInput.setClient':
        _client = methodCall.arguments[0];
        break;
      case 'TextInput.setEditingState':
        editingState = methodCall.arguments;
        break;
    }
  }

  void updateEditingValue(TextEditingValue value) {
    expect(_client, isNonZero);
    PlatformMessages.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        new MethodCall(
          'TextInputClient.updateEditingState',
          <dynamic>[_client, value.toJSON()],
        ),
      ),
      (ByteData data) { /* response from framework is discarded */ },
    );
  }

  void enterText(String text) {
    updateEditingValue(new TextEditingValue(
      text: text,
      composing: new TextRange(start: 0, end: text.length),
    ));
  }
}
