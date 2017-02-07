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
    PlatformMessages.setMockJSONMessageHandler('flutter/textinput', handleJSONMessage);
  }

  int _client = 0;
  Map<String, dynamic> editingState;

  Future<dynamic> handleJSONMessage(dynamic message) async {
    final String method = message['method'];
    final List<dynamic> args= message['args'];
    switch (method) {
      case 'TextInput.setClient':
        _client = args[0];
        break;
      case 'TextInput.setEditingState':
        editingState = args[0];
        break;
    }
  }

  void updateEditingState(TextEditingState state) {
    expect(_client, isNonZero);
    String message = JSON.encode(<String, dynamic>{
      'method': 'TextInputClient.updateEditingState',
      'args': <dynamic>[_client, state.toJSON()],
    });
    Uint8List encoded = UTF8.encoder.convert(message);
    PlatformMessages.handlePlatformMessage(
        _kTextInputClientChannel, encoded.buffer.asByteData(), (_) {});
  }

  void enterText(String text) {
    updateEditingState(new TextEditingState(
      text: text,
      composingBase: 0,
      composingExtent: text.length,
    ));
  }
}
