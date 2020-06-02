// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show
  FontWeight,
  Offset,
  Size,
  TextAffinity,
  TextAlign,
  TextDirection,
  hashValues;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'autofill.dart';
import 'message_codec.dart';
import 'platform_channel.dart';
import 'system_channels.dart';
import 'system_chrome.dart';
import 'text_editing.dart';

export 'dart:ui' show TextAffinity;

/// An interface to the system's text input control.
class TextInput {
  TextInput._() {
    _channel = SystemChannels.textInput;
    _channel.setMethodCallHandler(_handleTextInputInvocation);
  }

  /// Set the [MethodChannel] used to communicate with the system's text input
  /// control.
  ///
  /// This is only meant for testing within the Flutter SDK. Changing this
  /// will break the ability to input text. This has no effect if asserts are
  /// disabled.
  @visibleForTesting
  static void setChannel(MethodChannel newChannel) {
    assert(() {
      _instance._channel = newChannel..setMethodCallHandler(_instance._handleTextInputInvocation);
      return true;
    }());
  }

  static final TextInput _instance = TextInput._();

  static const List<TextInputAction> _androidSupportedInputActions = <TextInputAction>[
    TextInputAction.none,
    TextInputAction.unspecified,
    TextInputAction.done,
    TextInputAction.send,
    TextInputAction.go,
    TextInputAction.search,
    TextInputAction.next,
    TextInputAction.previous,
    TextInputAction.newline,
  ];

  static const List<TextInputAction> _iOSSupportedInputActions = <TextInputAction>[
    TextInputAction.unspecified,
    TextInputAction.done,
    TextInputAction.send,
    TextInputAction.go,
    TextInputAction.search,
    TextInputAction.next,
    TextInputAction.newline,
    TextInputAction.continueAction,
    TextInputAction.join,
    TextInputAction.route,
    TextInputAction.emergencyCall,
  ];

  /// Begin interacting with the text input control.
  ///
  /// Calling this function helps multiple clients coordinate about which one is
  /// currently interacting with the text input control. The returned
  /// [TextInputConnection] provides an interface for actually interacting with
  /// the text input control.
  ///
  /// A client that no longer wishes to interact with the text input control
  /// should call [TextInputConnection.close] on the returned
  /// [TextInputConnection].
  static TextInputConnection attach(TextInputClient client, TextInputConfiguration configuration) {
    assert(client != null);
    assert(configuration != null);
    final TextInputConnection connection = TextInputConnection._(client);
    _instance._attach(connection, configuration);
    return connection;
  }

  /// This method actually notifies the embedding of the client. It is utilized
  /// by [attach] and by [_handleTextInputInvocation] for the
  /// `TextInputClient.requestExistingInputState` method.
  void _attach(TextInputConnection connection, TextInputConfiguration configuration) {
    assert(connection != null);
    assert(connection._client != null);
    assert(configuration != null);
    assert(_debugEnsureInputActionWorksOnPlatform(configuration.inputAction));
    _channel.invokeMethod<void>(
      'TextInput.setClient',
      <dynamic>[ connection._id, configuration.toJson() ],
    );
    _currentConnection = connection;
    _currentConfiguration = configuration;
  }

  static bool _debugEnsureInputActionWorksOnPlatform(TextInputAction inputAction) {
    assert(() {
      if (kIsWeb) {
        // TODO(flutterweb): what makes sense here?
        return true;
      }
      if (Platform.isIOS) {
        assert(
          _iOSSupportedInputActions.contains(inputAction),
          'The requested TextInputAction "$inputAction" is not supported on iOS.',
        );
      } else if (Platform.isAndroid) {
        assert(
          _androidSupportedInputActions.contains(inputAction),
          'The requested TextInputAction "$inputAction" is not supported on Android.',
        );
      }
      return true;
    }());
    return true;
  }

  MethodChannel _channel;

  TextInputConnection _currentConnection;
  TextInputConfiguration _currentConfiguration;

  Future<dynamic> _handleTextInputInvocation(MethodCall methodCall) async {
    if (_currentConnection == null)
      return;
    final String method = methodCall.method;

    // The requestExistingInputState request needs to be handled regardless of
    // the client ID, as long as we have a _currentConnection.
    if (method == 'TextInputClient.requestExistingInputState') {
      assert(_currentConnection._client != null);
      _attach(_currentConnection, _currentConfiguration);
      final TextEditingValue editingValue = _currentConnection._client.currentTextEditingValue;
      if (editingValue != null) {
        _setEditingState(editingValue);
      }
      return;
    }

    final List<dynamic> args = methodCall.arguments as List<dynamic>;

    if (method == 'TextInputClient.updateEditingStateWithTag') {
      final TextInputClient client = _currentConnection._client;
      assert(client != null);
      final AutofillScope scope = client.currentAutofillScope;
      final Map<String, dynamic> editingValue = args[1] as Map<String, dynamic>;
      for (final String tag in editingValue.keys) {
        final TextEditingValue textEditingValue = TextEditingValue.fromJSON(
          editingValue[tag] as Map<String, dynamic>,
        );
        scope?.getAutofillClient(tag)?.updateEditingValue(textEditingValue);
      }

      return;
    }

    final int client = args[0] as int;
    // The incoming message was for a different client.
    if (client != _currentConnection._id)
      return;
    switch (method) {
      case 'TextInputClient.updateEditingState':
        _currentConnection._client.updateEditingValue(TextEditingValue.fromJSON(args[1] as Map<String, dynamic>));
        break;
      case 'TextInputClient.performAction':
        _currentConnection._client.performAction(_toTextInputAction(args[1] as String));
        break;
      case 'TextInputClient.updateFloatingCursor':
        _currentConnection._client.updateFloatingCursor(_toTextPoint(
          _toTextCursorAction(args[1] as String),
          args[2] as Map<String, dynamic>,
        ));
        break;
      case 'TextInputClient.onConnectionClosed':
        _currentConnection._client.connectionClosed();
        break;
      case 'TextInputClient.showAutocorrectionPromptRect':
        _currentConnection._client.showAutocorrectionPromptRect(args[1] as int, args[2] as int);
        break;
      default:
        throw MissingPluginException();
    }
  }

  bool _hidePending = false;

  void _scheduleHide() {
    if (_hidePending)
      return;
    _hidePending = true;

    // Schedule a deferred task that hides the text input. If someone else
    // shows the keyboard during this update cycle, then the task will do
    // nothing.
    scheduleMicrotask(() {
      _hidePending = false;
      if (_currentConnection == null)
        _channel.invokeMethod<void>('TextInput.hide');
    });
  }

  void _clearClient() {
    _channel.invokeMethod<void>('TextInput.clearClient');
    _currentConnection = null;
    _scheduleHide();
  }

  void _setEditingState(TextEditingValue value) {
    assert(value != null);
    _channel.invokeMethod<void>(
      'TextInput.setEditingState',
      value.toJSON(),
    );
  }

  void _show() {
    _channel.invokeMethod<void>('TextInput.show');
  }

  void _requestAutofill() {
    _channel.invokeMethod<void>('TextInput.requestAutofill');
  }

  void _setEditableSizeAndTransform(Map<String, dynamic> args) {
    _channel.invokeMethod<void>(
      'TextInput.setEditableSizeAndTransform',
      args,
    );
  }

  void _setStyle(Map<String, dynamic> args) {
    _channel.invokeMethod<void>(
      'TextInput.setStyle',
      args,
    );
  }
}
