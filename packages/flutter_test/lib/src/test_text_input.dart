// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
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
    flutterTextInputChannel.setMockMethodCallHandler(handleTextInputCall);
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

  void updateEditingState(TextEditingState state) {
    expect(_client, isNonZero);
    PlatformMessages.handlePlatformMessage(
      flutterTextInputClientChannel.name,
      flutterTextInputClientChannel.codec.encodeMethodCall(
        new MethodCall(
          'TextInputClient.updateEditingState',
          <dynamic>[_client, state.toJSON()]
        ),
      ),
      (_) {}
    );
  }

  void enterText(String text) {
    updateEditingState(new TextEditingState(
      text: text,
      composingBase: 0,
      composingExtent: text.length,
    ));
  }
}
