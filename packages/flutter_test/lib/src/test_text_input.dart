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
/// The [TestWidgetsFlutterBinding] class registers a [TestTextInput] instance
/// ([TestWidgetsFlutterBinding.testTextInput]) as a stub keyboard
/// implementation if its [TestWidgetsFlutterBinding.registerTestTextInput]
/// property returns true when a test starts, and unregisters it when the test
/// ends (unless it ends with a failure).
///
/// See [register], [unregister], and [isRegistered] for details.
///
/// The [updateEditingValue], [enterText], and [receiveAction] methods can be
/// used even when the [TestTextInput] is not registered. All other methods
/// will assert if [isRegistered] is false.
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

  /// Log for method calls.
  ///
  /// For all registered channels, handled calls are added to the list. Can
  /// be cleaned using `log.clear()`.
  final List<MethodCall> log = <MethodCall>[];

  /// Resets any internal state of this object.
  ///
  /// This method is invoked by the testing framework between tests. It should
  /// not ordinarily be called by tests directly.
  void reset() {
    log.clear();
    editingState = null;
    setClientArgs = null;
    _client = 0;
    _isVisible = false;
  }

  /// Installs this object as a mock handler for [SystemChannels.textInput].
  ///
  /// Called by the binding at the top of a test when
  /// [TestWidgetsFlutterBinding.registerTestTextInput] is true.
  void register() => SystemChannels.textInput.setMockMethodCallHandler(_handleTextInputCall);

  /// Removes this object as a mock handler for [SystemChannels.textInput].
  ///
  /// After calling this method, the channel will exchange messages with the
  /// Flutter engine instead of the stub.
  ///
  /// Called by the binding at the end of a (successful) test when
  /// [TestWidgetsFlutterBinding.registerTestTextInput] is true.
  void unregister() => SystemChannels.textInput.setMockMethodCallHandler(null);

  /// Whether this [TestTextInput] is registered with [SystemChannels.textInput].
  ///
  /// The binding uses the [register] and [unregister] methods to control this
  /// value when [TestWidgetsFlutterBinding.registerTestTextInput] is true.
  bool get isRegistered => SystemChannels.textInput.checkMockMethodCallHandler(_handleTextInputCall);

  /// Whether there are any active clients listening to text input.
  bool get hasAnyClients {
    assert(isRegistered);
    return _client > 0;
  }

  int _client = 0;

  /// The last set of arguments supplied to the `TextInput.setClient` and
  /// `TextInput.updateConfig` methods of this stub implementation.
  Map<String, dynamic>? setClientArgs;

  /// The last set of arguments that [TextInputConnection.setEditingState] sent
  /// to this stub implementation (i.e. the arguments set to
  /// `TextInput.setEditingState`).
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
        if (onCleared != null)
          onCleared!();
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
  ///
  /// Specifically, this reflects the last call to `TextInput.show` or
  /// `TextInput.hide` received by the stub implementation.
  bool get isVisible {
    assert(isRegistered);
    return _isVisible;
  }
  bool _isVisible = false;

  /// Simulates the user hiding the onscreen keyboard.
  ///
  /// This does nothing but set the internal flag.
  void hide() {
    assert(isRegistered);
    _isVisible = false;
  }

  /// Simulates the user changing the [TextEditingValue] to the given value.
  ///
  /// This can be called even if the [TestTextInput] has not been [register]ed.
  void updateEditingValue(TextEditingValue value) {
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
  ///
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
  /// This can be called even if the [TestTextInput] has not been [register]ed.
  void enterText(String text) {
    updateEditingValue(TextEditingValue(
      text: text,
    ));
  }

  /// Simulates the user pressing one of the [TextInputAction] buttons.
  /// Does not check that the [TextInputAction] performed is an acceptable one
  /// based on the `inputAction` [setClientArgs].
  ///
  /// This can be called even if the [TestTextInput] has not been [register]ed.
  Future<void> receiveAction(TextInputAction action) async {
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
}
