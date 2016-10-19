// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show TextAffinity;

import 'package:flutter/foundation.dart';

import 'platform_messages.dart';

export 'dart:ui' show TextAffinity;

/// For which type of information to optimize the text input control.
enum TextInputType {
  /// Optimize for textual information.
  text,

  /// Optimize for numerical information.
  number,

  /// Optimize for telephone numbers.
  phone,

  /// Optimize for date and time information.
  datetime,
}

/// A action the user has requested the text input control to perform.
enum TextInputAction {
  /// Complete the text input operation.
  done,
}

/// Controls the visual appearance of the text input control.
///
/// See also:
///
///  * [TextInput.attach]
class TextInputConfiguration {
  /// Creates configuration information for a text input control.
  ///
  /// The [inputType] argument must not be null.
  const TextInputConfiguration({
    this.inputType: TextInputType.text,
    this.actionLabel,
  });

  /// For which type of information to optimize the text input control.
  final TextInputType inputType;

  /// What text to display in the text input control's action button.
  final String actionLabel;

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'inputType': inputType.toString(),
      'actionLabel': actionLabel,
    };
  }
}

TextAffinity _toTextAffinity(String affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}

/// The current text, selection, and composing state for editing a run of text.
class TextEditingState {
  /// Creates state for text editing.
  ///
  /// The [selectionBase], [selectionExtent], [selectionAffinity],
  /// [selectionIsDirectional], [selectionIsDirectional], [composingBase], and
  /// [composingExtent] arguments must not be null.
  const TextEditingState({
    this.text,
    this.selectionBase: -1,
    this.selectionExtent: -1,
    this.selectionAffinity: TextAffinity.downstream,
    this.selectionIsDirectional: false,
    this.composingBase: -1,
    this.composingExtent: -1,
  });

  /// The text that is currently being edited.
  final String text;

  /// The offset in [text] at which the selection originates.
  ///
  /// Might be larger than, smaller than, or equal to [selectionExtent].
  final int selectionBase;

  /// The offset in [text] at which the selection terminates.
  ///
  /// When the user uses the arrow keys to adjust the selection, this is the
  /// value that changes. Similarly, if the current theme paints a caret on one
  /// side of the selection, this is the location at which to paint the caret.
  ///
  /// Might be larger than, smaller than, or equal to [selectionBase].
  final int selectionExtent;

  /// If the the text range is collapsed and has more than one visual location
  /// (e.g., occurs at a line break), which of the two locations to use when
  /// painting the caret.
  final TextAffinity selectionAffinity;

  /// Whether this selection has disambiguated its base and extent.
  ///
  /// On some platforms, the base and extent are not disambiguated until the
  /// first time the user adjusts the selection. At that point, either the start
  /// or the end of the selection becomes the base and the other one becomes the
  /// extent and is adjusted.
  final bool selectionIsDirectional;

  /// The offset in [text] at which the composing region originates.
  ///
  /// Always smaller than, or equal to, [composingExtent].
  final int composingBase;

  /// The offset in [text] at which the selection terminates.
  ///
  /// Always larger than, or equal to, [composingBase].
  final int composingExtent;

  /// Creates an instance of this class from a JSON object.
  factory TextEditingState.fromJSON(Map<String, dynamic> encoded) {
    return new TextEditingState(
      text: encoded['text'],
      selectionBase: encoded['selectionBase'] ?? -1,
      selectionExtent: encoded['selectionExtent'] ?? -1,
      selectionIsDirectional: encoded['selectionIsDirectional'] ?? false,
      selectionAffinity: _toTextAffinity(encoded['selectionAffinity']) ?? TextAffinity.downstream,
      composingBase: encoded['composingBase'] ?? -1,
      composingExtent: encoded['composingExtent'] ?? -1,
    );
  }

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'selectionBase': selectionBase,
      'selectionExtent': selectionExtent,
      'selectionAffinity': selectionAffinity.toString(),
      'selectionIsDirectional': selectionIsDirectional,
      'composingBase': composingBase,
      'composingExtent': composingExtent,
    };
  }
}

/// An interface to receive information from [TextInput].
///
/// See also:
///
///  * [TextInput.attach]
abstract class TextInputClient {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TextInputClient();

  /// Requests that this client update its editing state to the given value.
  void updateEditingState(TextEditingState state);

  /// Requests that this client perform the given action.
  void performAction(TextInputAction action);
}

const String _kChannelName = 'flutter/textinput';

/// A interface for interacting with a text input control.
///
/// See also:
///
///  * [TextInput.attach]
class TextInputConnection {
  TextInputConnection._(this._client) : _id = _nextId++ {
    assert(_client != null);
  }

  static int _nextId = 1;
  final int _id;

  final TextInputClient _client;

  /// Whether this connection is currently interacting with the text input control.
  bool get attached => _clientHandler._currentConnection == this;

  /// Requests that the text input control become visible.
  void show() {
    assert(attached);
    PlatformMessages.invokeMethod(_kChannelName, 'TextInput.show');
  }

  /// Requests that the text input control change its internal state to match the given state.
  void setEditingState(TextEditingState state) {
    assert(attached);
    PlatformMessages.invokeMethod(
      _kChannelName,
      'TextInput.setEditingState',
      <dynamic>[ state.toJSON() ],
    );
  }

  /// Stop interacting with the text input control.
  ///
  /// After calling this method, the text input control might disappear if no
  /// other client attaches to it within this animation frame.
  void close() {
    if (attached) {
      PlatformMessages.invokeMethod(_kChannelName, 'TextInput.clearClient');
      _clientHandler
        .._currentConnection = null
        .._scheduleHide();
    }
    assert(!attached);
  }
}

TextInputAction _toTextInputAction(String action) {
  switch (action) {
    case 'TextInputAction.done':
      return TextInputAction.done;
  }
  throw new FlutterError('Unknow text input action: $action');
}

class _TextInputClientHandler {
  _TextInputClientHandler() {
    PlatformMessages.setJSONMessageHandler('flutter/textinputclient', _handleMessage);
  }

  TextInputConnection _currentConnection;

  Future<Null> _handleMessage(dynamic message) async {
    if (_currentConnection == null)
      return;
    final String method = message['method'];
    final List<dynamic> args = message['args'];
    final int client = args[0];
    // The incoming message was for a different client.
    if (client != _currentConnection._id)
      return;
    switch (method) {
      case 'TextInputClient.updateEditingState':
        _currentConnection._client.updateEditingState(new TextEditingState.fromJSON(args[1]));
        break;
      case 'TextInputClient.performAction':
        _currentConnection._client.performAction(_toTextInputAction(args[1]));
        break;
    }
  }

  bool _hidePending = false;

  void _scheduleHide() {
    if (_hidePending)
      return;
    _hidePending = true;

    // Schedule a deferred task that hides the text input.  If someone else
    // shows the keyboard during this update cycle, then the task will do
    // nothing.
    scheduleMicrotask(() {
      _hidePending = false;
      if (_currentConnection == null)
        PlatformMessages.invokeMethod(_kChannelName, 'TextInput.hide');
    });
  }
}

final _TextInputClientHandler _clientHandler = new _TextInputClientHandler();

/// An interface to the system's text input control.
class TextInput {
  TextInput._();

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
    final TextInputConnection connection = new TextInputConnection._(client);
    _clientHandler._currentConnection = connection;
    PlatformMessages.invokeMethod(
      _kChannelName,
      'TextInput.setClient',
      <dynamic>[ connection._id, configuration.toJSON() ],
    );
    return connection;
  }
}
