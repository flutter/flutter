// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';


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
  final VoidCallback? onCleared;

  /// The messenger which sends the bytes for this channel, not null.
  BinaryMessenger get _binaryMessenger => ServicesBinding.instance!.defaultBinaryMessenger;

  /// Resets any internal state of this object and calls [register].
  ///
  /// This method is invoked by the testing framework between tests. It should
  /// not ordinarily be called by tests directly.
  void resetAndRegister() {
    log.clear();
    editingState = null;
    setClientArgs = null;
    _client = 0;
    _isVisible = false;
    register();
  }
  /// Installs this object as a mock handler for [SystemChannels.textInput].
  void register() => SystemChannels.textInput.setMockMethodCallHandler(_handleTextInputCall);

  /// Removes this object as a mock handler for [SystemChannels.textInput].
  ///
  /// After calling this method, the channel will exchange messages with the
  /// Flutter engine. Use this with [FlutterDriver] tests that need to display
  /// on-screen keyboard provided by the operating system.
  void unregister() => SystemChannels.textInput.setMockMethodCallHandler(null);

  /// Log for method calls.
  ///
  /// For all registered channels, handled calls are added to the list. Can
  /// be cleaned using `log.clear()`.
  final List<MethodCall> log = <MethodCall>[];

  /// Whether this [TestTextInput] is registered with [SystemChannels.textInput].
  ///
  /// Use [register] and [unregister] methods to control this value.
  bool get isRegistered => SystemChannels.textInput.checkMockMethodCallHandler(_handleTextInputCall);

  /// Whether there are any active clients listening to text input.
  bool get hasAnyClients {
    assert(isRegistered);
    return _client > 0;
  }

  int _client = 0;

  /// Arguments supplied to the TextInput.setClient method call.
  Map<String, dynamic>? setClientArgs;

  /// The last set of arguments that [TextInputConnection.setEditingState] sent
  /// to the embedder.
  ///
  /// This is a map representation of a [TextEditingValue] object. For example,
  /// it will have a `text` entry whose value matches the most recent
  /// [TextEditingValue.text] that was sent to the embedder.
  Map<String, dynamic>? editingState;

  Future<dynamic> _handleTextInputCall(MethodCall methodCall) async {
    log.add(methodCall);
    switch (methodCall.method) {
      case 'TextInput.setClient':
        _client = methodCall.arguments[0] as int;
        setClientArgs = methodCall.arguments[1] as Map<String, dynamic>;
        break;
      case 'TextInput.updateConfig':
        setClientArgs = methodCall.arguments as Map<String, dynamic>;
        break;
      case 'TextInput.clearClient':
        _client = 0;
        _isVisible = false;
        onCleared?.call();
        break;
      case 'TextInput.setEditingState':
        editingState = methodCall.arguments as Map<String, dynamic>;
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
  bool get isVisible {
    assert(isRegistered);
    return _isVisible;
  }
  bool _isVisible = false;

  /// Simulates the user changing the [TextEditingValue] to the given value.
  void updateEditingValue(TextEditingValue value) {
    assert(isRegistered);
    // Not using the `expect` function because in the case of a FlutterDriver
    // test this code does not run in a package:test test zone.
    if (_client == 0)
      throw TestFailure('Tried to use TestTextInput with no keyboard attached. You must use WidgetTester.showKeyboard() first.');
    _binaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingState',
          <dynamic>[_client, value.toJSON()],
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );
  }

  /// Simulates the user closing the text input connection.
  ///
  /// For example:
  /// - User pressed the home button and sent the application to background.
  /// - User closed the virtual keyboard.
  void closeConnection() {
    assert(isRegistered);
    // Not using the `expect` function because in the case of a FlutterDriver
    // test this code does not run in a package:test test zone.
    if (_client == 0)
      throw TestFailure('Tried to use TestTextInput with no keyboard attached. You must use WidgetTester.showKeyboard() first.');
    _binaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.onConnectionClosed',
           <dynamic>[_client,]
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );
  }

  /// Simulates the user typing the given text.
  ///
  /// Calling this method replaces the content of the connected input field with
  /// `text`, and places the caret at the end of the text.
  void enterText(String text) {
    assert(isRegistered);
    updateEditingValue(TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ));
  }

  /// Simulates the user pressing one of the [TextInputAction] buttons.
  /// Does not check that the [TextInputAction] performed is an acceptable one
  /// based on the `inputAction` [setClientArgs].
  Future<void> receiveAction(TextInputAction action) async {
    assert(isRegistered);
    return TestAsyncUtils.guard(() {
      // Not using the `expect` function because in the case of a FlutterDriver
      // test this code does not run in a package:test test zone.
      if (_client == 0) {
        throw TestFailure('Tried to use TestTextInput with no keyboard attached. You must use WidgetTester.showKeyboard() first.');
      }

      final Completer<void> completer = Completer<void>();

      _binaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          MethodCall(
            'TextInputClient.performAction',
            <dynamic>[_client, action.toString()],
          ),
        ),
        (ByteData? data) {
          assert(data != null);
          try {
            // Decoding throws a PlatformException if the data represents an
            // error, and that's all we care about here.
            SystemChannels.textInput.codec.decodeEnvelope(data!);

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
    assert(isRegistered);
    _isVisible = false;
  }
}
