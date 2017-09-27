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
  /// Installs this object as a mock handler for [SystemChannels.textInput].
  void register() {
    SystemChannels.textInput.setMockMethodCallHandler(_handleTextInputCall);
  }

  int _client = 0;

  /// Arguments supplied to the TextInput.setClient method call.
  Map<String, dynamic> setClientArgs;

  /// The last set of arguments that [TextInputConnection.setEditingState] sent
  /// to the embedder.
  ///
  /// This is a map representation of a [TextEditingValue] object. For example,
  /// it will have a `text` entry whose value matches the most recent
  /// [TextEditingValue.text] that was sent to the embedder.
  Map<String, dynamic> editingState;

  Future<dynamic> _handleTextInputCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'TextInput.setClient':
        _client = methodCall.arguments[0];
        setClientArgs = methodCall.arguments[1];
        break;
      case 'TextInput.clearClient':
        _client = 0;
        _isVisible = false;
        break;
      case 'TextInput.setEditingState':
        editingState = methodCall.arguments;
        break;
      case 'TextInput.show':
        _isVisible = true;
        break;
      case 'TextInput.hide':
        _isVisible = false;
        break;
    }
  }

  /// Whether the onscreen keyboard is visible to the user.
  bool get isVisible => _isVisible;
  bool _isVisible = false;

  /// Simulates the user changing the [TextEditingValue] to the given value.
  void updateEditingValue(TextEditingValue value) {
    expect(_client, isNonZero);
    BinaryMessages.handlePlatformMessage(
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

  /// Simulates the user typing the given text.
  void enterText(String text) {
    updateEditingValue(new TextEditingValue(
      text: text,
      composing: new TextRange(start: 0, end: text.length),
    ));
  }

  /// Simulates the user hiding the onscreen keyboard.
  void hide() {
    _isVisible = false;
  }
}
