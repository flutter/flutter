// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../../services.dart';

/// A low-level interface to the system's undo manager.
///
/// To receive events from the system UndoManager, create an
/// [UndoManagerClient] and set it as the [client] on [UndoManager].
///
/// The [setUndoState] method can be used to update the system's UndoManager
/// using the [canUndo] and [canRedo] parameters.
///
/// When the system undo or redo button is tapped, the current
/// [UndoManagerClient] will receive [UndoManagerClient.handlePlatformUndo]
/// with a string representing whether the event is "undo" or "redo".
///
/// Currently, only iOS has an UndoManagerPlugin implemented on the engine side.
///
/// See also:
///
/// * [NSUndoManager](https://developer.apple.com/documentation/foundation/nsundomanager)
class UndoManager {
  UndoManager._() {
    _channel = SystemChannels.undoManager;
    _channel.setMethodCallHandler(_handleUndoManagerInvocation);
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
      _instance._channel = newChannel..setMethodCallHandler(_instance._handleUndoManagerInvocation);
      return true;
    }());
  }

  static final UndoManager _instance = UndoManager._();

  /// Receive undo and redo events from the system's UndoManager.
  ///
  /// Setting the [client] will cause [UndoManagerClient.handlePlatformUndo]
  /// to be called when a system undo or redo is triggered, such as by tapping
  /// the undo/redo keyboard buttons or using the 3-finger swipe gestures.
  static set client(UndoManagerClient? client) {
    _instance._currentClient = client;
  }

  /// Return the current [UndoManagerClient].
  static UndoManagerClient? get client => _instance._currentClient;

  /// Set the current state of the system UndoManager. [canUndo] and [canRedo]
  /// control the respective "undo" and "redo" buttons of the system UndoManager.
  static void setUndoState({bool canUndo = false, bool canRedo = false}) {
    _instance._setUndoState(canUndo: canUndo, canRedo: canRedo);
  }

  late MethodChannel _channel;

  UndoManagerClient? _currentClient;

  Future<dynamic> _handleUndoManagerInvocation(MethodCall methodCall) async {
    final String method = methodCall.method;
    final List<dynamic> args = methodCall.arguments as List<dynamic>;
    if (method == 'UndoManagerClient.handleUndo') {
      assert(_currentClient != null, 'There must be a current UndoManagerClient.');
      _currentClient!.handlePlatformUndo(args[0] as String);

      return;
    }

    throw MissingPluginException();
  }

  void _setUndoState({bool canUndo = false, bool canRedo = false}) {
    _channel.invokeMethod<void>(
      'UndoManager.setUndoState',
      <String, bool>{'canUndo': canUndo, 'canRedo': canRedo}
    );
  }
}

/// An interface to receive events from a native UndoManager.
abstract class UndoManagerClient {
  /// Requests that the client perform an undo or redo operation.
  ///
  /// Currently only used on iOS 9+ when the undo or redo methods are invoked
  /// by the platform. For example, when using three-finger swipe gestures,
  /// the iPad keyboard, or voice control.
  void handlePlatformUndo(String direction);

  /// Reverts the value on the stack to the previous value.
  void undo();

  /// Updates the value on the stack to the next value.
  void redo();

  /// Will be true if there are past values on the stack.
  bool get canUndo;

  /// Will be false if there are future values on the stack.
  bool get canRedo;
}
