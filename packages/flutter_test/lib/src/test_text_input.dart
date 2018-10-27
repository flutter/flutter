// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import 'widget_tester.dart';

export 'package:flutter/services.dart' show TextEditingValue, TextInputAction;

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
  /// Create a fake keyboard backend.
  ///
  /// The [onCleared] argument may be set to be notified of when the keyboard
  /// is dismissed.
  TestTextInput({ this.onCleared });

  /// Called when the keyboard goes away.
  ///
  /// To use the methods on this API that send fake keyboard messages (such as
  /// [updateEditingValue], [enterText], or [receiveAction]), the keyboard must
  /// first be requested, e.g. using [WidgetTester.showKeyboard].
  final VoidCallback onCleared;

  /// Installs this object as a mock handler for [SystemChannels.textInput].
  void register() {
    SystemChannels.textInput.setMockMethodCallHandler(_handleTextInputCall);
    _isRegistered = true;
  }

  /// Removes this object as a mock handler for [SystemChannels.textInput].
  ///
  /// After calling this method, the channel will exchange messages with the
  /// Flutter engine. Use this with [FlutterDriver] tests that need to display
  /// on-screen keyboard provided by the operating system.
  void unregister() {
    SystemChannels.textInput.setMockMethodCallHandler(null);
    _isRegistered = false;
  }

  /// Whether this [TestTextInput] is registered with [SystemChannels.textInput].
  ///
  /// Use [register] and [unregister] methods to control this value.
  bool get isRegistered => _isRegistered;
  bool _isRegistered = false;

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
        if (onCleared != null)
          onCleared();
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
    // Not using the `expect` function because in the case of a FlutterDriver
    // test this code does not run in a package:test test zone.
    if (_client == 0)
      throw TestFailure('Tried to use TestTextInput with no keyboard attached. You must use WidgetTester.showKeyboard() first.');
    BinaryMessages.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingState',
          <dynamic>[_client, value.toJSON()],
        ),
      ),
      (ByteData data) { /* response from framework is discarded */ },
    );
  }

  /// Simulates the user typing the given text.
  void enterText(String text) {
    updateEditingValue(TextEditingValue(
      text: text,
    ));
  }

  /// Simulates the user pressing one of the [TextInputAction] buttons.
  /// Does not check that the [TextInputAction] performed is an acceptable one
  /// based on the `inputAction` [setClientArgs].
  Future<void> receiveAction(TextInputAction action) async {
    return TestAsyncUtils.guard(() {
      // Not using the `expect` function because in the case of a FlutterDriver
      // test this code does not run in a package:test test zone.
      if (_client == 0) {
        throw TestFailure('Tried to use TestTextInput with no keyboard attached. You must use WidgetTester.showKeyboard() first.');
      }

      final Completer<void> completer = Completer<void>();

      BinaryMessages.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          MethodCall(
            'TextInputClient.performAction',
            <dynamic>[_client, action.toString()],
          ),
        ),
        (ByteData data) {
          try {
            // Decoding throws a PlatformException if the data represents an
            // error, and that's all we care about here.
            SystemChannels.textInput.codec.decodeEnvelope(data);

            // No error was found. Complete without issue.
            completer.complete();
          } catch (error) {
            // An exception occurred as a result of receiveAction()'ing. Report
            // that error.
            completer.completeError(error);
          }
        },
      );

      return completer.future;
    });
  }

  /// Simulates the user hiding the onscreen keyboard.
  void hide() {
    _isVisible = false;
  }
}
