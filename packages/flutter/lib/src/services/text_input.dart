// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show TextAffinity, hashValues;

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'system_channels.dart';
import 'text_editing.dart';

export 'dart:ui' show TextAffinity;

/// The type of information for which to optimize the text input control.
///
/// On Android, behavior may vary across device and keyboard provider.
///
/// This class stays as close to [Enum] interface as possible, and allows
/// for additional flags for some input types. For example, numeric input
/// can specify whether it supports decimal numbers and/or signed numbers.
class TextInputType {
  const TextInputType._(this.index) : signed = null, decimal = null;

  /// Optimize for textual information.
  ///
  /// Requests a numeric keyboard with additional settings.
  /// The [signed] and [decimal] parameters are optional.
  const TextInputType.numberWithOptions({
    this.signed: false,
    this.decimal: false,
  }) : index = 2;

  /// Enum value index, corresponds to one of the [values].
  final int index;

  /// The number is signed, allowing a positive or negative sign at the start.
  ///
  /// This flag is only used for the [number] input type, otherwise `null`.
  /// Use `const TextInputType.numberWithOptions(signed: true)` to set this.
  final bool signed;

  /// The number is decimal, allowing a decimal point to provide fractional.
  ///
  /// This flag is only used for the [number] input type, otherwise `null`.
  /// Use `const TextInputType.numberWithOptions(decimal: true)` to set this.
  final bool decimal;

  /// Optimize for textual information.
  ///
  /// Requests the default platform keyboard.
  static const TextInputType text = const TextInputType._(0);

  /// Optimize for multi-line textual information.
  ///
  /// Requests the default platform keyboard, but accepts newlines when the
  /// enter key is pressed. This is the input type used for all multi-line text
  /// fields.
  static const TextInputType multiline = const TextInputType._(1);

  /// Optimize for numerical information.
  ///
  /// Requests a default keyboard with ready access to the number keys.
  /// Additional options, such as decimal point and/or positive/negative
  /// signs, can be requested using [new TextInputType.numberWithOptions].
  static const TextInputType number = const TextInputType.numberWithOptions();

  /// Optimize for telephone numbers.
  ///
  /// Requests a keyboard with ready access to the number keys, "*", and "#".
  static const TextInputType phone = const TextInputType._(3);

  /// Optimize for date and time information.
  ///
  /// On iOS, requests the default keyboard.
  ///
  /// On Android, requests a keyboard with ready access to the number keys,
  /// ":", and "-".
  static const TextInputType datetime = const TextInputType._(4);

  /// Optimize for email addresses.
  ///
  /// Requests a keyboard with ready access to the "@" and "." keys.
  static const TextInputType emailAddress = const TextInputType._(5);

  /// Optimize for URLs.
  ///
  /// Requests a keyboard with ready access to the "/" and "." keys.
  static const TextInputType url = const TextInputType._(6);

  /// All possible enum values.
  static const List<TextInputType> values = const <TextInputType>[
    text, multiline, number, phone, datetime, emailAddress, url,
  ];

  // Corresponding string name for each the [values].
  static const List<String> _names = const <String>[
    'text', 'multiline', 'number', 'phone', 'datetime', 'emailAddress', 'url',
  ];

  // Enum value name, this is what enum.toString() would normally return.
  String get _name => 'TextInputType.${_names[index]}';

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'name': _name,
      'signed': signed,
      'decimal': decimal,
    };
  }

  @override
  String toString() {
    return '$runtimeType('
        'name: $_name, '
        'signed: $signed, '
        'decimal: $decimal)';
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! TextInputType)
      return false;
    final TextInputType typedOther = other;
    return typedOther.index == index
        && typedOther.signed == signed
        && typedOther.decimal == decimal;
  }

  @override
  int get hashCode => hashValues(index, signed, decimal);
}

/// An action the user has requested the text input control to perform.
enum TextInputAction {
  /// Complete the text input operation.
  done,

  /// The action to take when the enter button is pressed in a multi-line
  /// text field (which is typically to do nothing).
  newline,
}

/// Controls the visual appearance of the text input control.
///
/// See also:
///
///  * [TextInput.attach]
@immutable
class TextInputConfiguration {
  /// Creates configuration information for a text input control.
  ///
  /// All arguments have default values, except [actionLabel]. Only
  /// [actionLabel] may be null.
  const TextInputConfiguration({
    this.inputType: TextInputType.text,
    this.obscureText: false,
    this.autocorrect: true,
    this.actionLabel,
    this.inputAction: TextInputAction.done,
  }) : assert(inputType != null),
       assert(obscureText != null),
       assert(autocorrect != null),
       assert(inputAction != null);

  /// The type of information for which to optimize the text input control.
  final TextInputType inputType;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true.
  final bool autocorrect;

  /// What text to display in the text input control's action button.
  final String actionLabel;

  /// What kind of action to request for the action button on the IME.
  final TextInputAction inputAction;

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'inputType': inputType.toJSON(),
      'obscureText': obscureText,
      'autocorrect': autocorrect,
      'actionLabel': actionLabel,
      'inputAction': inputAction.toString(),
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
@immutable
class TextEditingValue {
  /// Creates information for editing a run of text.
  ///
  /// The selection and composing range must be within the text.
  ///
  /// The [text], [selection], and [composing] arguments must not be null but
  /// each have default values.
  const TextEditingValue({
    this.text: '',
    this.selection: const TextSelection.collapsed(offset: -1),
    this.composing: TextRange.empty
  }) : assert(text != null),
       assert(selection != null),
       assert(composing != null);

  /// Creates an instance of this class from a JSON object.
  factory TextEditingValue.fromJSON(Map<String, dynamic> encoded) {
    return new TextEditingValue(
      text: encoded['text'],
      selection: new TextSelection(
        baseOffset: encoded['selectionBase'] ?? -1,
        extentOffset: encoded['selectionExtent'] ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity']) ?? TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] ?? false,
      ),
      composing: new TextRange(
        start: encoded['composingBase'] ?? -1,
        end: encoded['composingExtent'] ?? -1,
      ),
    );
  }

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'selectionBase': selection.baseOffset,
      'selectionExtent': selection.extentOffset,
      'selectionAffinity': selection.affinity.toString(),
      'selectionIsDirectional': selection.isDirectional,
      'composingBase': composing.start,
      'composingExtent': composing.end,
    };
  }

  /// The current text being edited.
  final String text;

  /// The range of text that is currently selected.
  final TextSelection selection;

  /// The range of text that is still being composed.
  final TextRange composing;

  /// A value that corresponds to the empty string with no selection and no composing range.
  static const TextEditingValue empty = const TextEditingValue();

  /// Creates a copy of this value but with the given fields replaced with the new values.
  TextEditingValue copyWith({
    String text,
    TextSelection selection,
    TextRange composing
  }) {
    return new TextEditingValue(
      text: text ?? this.text,
      selection: selection ?? this.selection,
      composing: composing ?? this.composing
    );
  }

  @override
  String toString() => '$runtimeType(text: \u2524$text\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextEditingValue)
      return false;
    final TextEditingValue typedOther = other;
    return typedOther.text == text
        && typedOther.selection == selection
        && typedOther.composing == composing;
  }

  @override
  int get hashCode => hashValues(
    text.hashCode,
    selection.hashCode,
    composing.hashCode
  );
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
  void updateEditingValue(TextEditingValue value);

  /// Requests that this client perform the given action.
  void performAction(TextInputAction action);
}

/// An interface for interacting with a text input control.
///
/// See also:
///
///  * [TextInput.attach]
class TextInputConnection {
  TextInputConnection._(this._client)
    : assert(_client != null),
      _id = _nextId++;

  static int _nextId = 1;
  final int _id;

  final TextInputClient _client;

  /// Whether this connection is currently interacting with the text input control.
  bool get attached => _clientHandler._currentConnection == this;

  /// Requests that the text input control become visible.
  void show() {
    assert(attached);
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  /// Requests that the text input control change its internal state to match the given state.
  void setEditingState(TextEditingValue value) {
    assert(attached);
    SystemChannels.textInput.invokeMethod(
      'TextInput.setEditingState',
      value.toJSON(),
    );
  }

  /// Stop interacting with the text input control.
  ///
  /// After calling this method, the text input control might disappear if no
  /// other client attaches to it within this animation frame.
  void close() {
    if (attached) {
      SystemChannels.textInput.invokeMethod('TextInput.clearClient');
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
    case 'TextInputAction.newline':
      return TextInputAction.newline;
  }
  throw new FlutterError('Unknown text input action: $action');
}

class _TextInputClientHandler {
  _TextInputClientHandler() {
    SystemChannels.textInput.setMethodCallHandler(_handleTextInputInvocation);
  }

  TextInputConnection _currentConnection;

  Future<dynamic> _handleTextInputInvocation(MethodCall methodCall) async {
    if (_currentConnection == null)
      return;
    final String method = methodCall.method;
    final List<dynamic> args = methodCall.arguments;
    final int client = args[0];
    // The incoming message was for a different client.
    if (client != _currentConnection._id)
      return;
    switch (method) {
      case 'TextInputClient.updateEditingState':
        _currentConnection._client.updateEditingValue(new TextEditingValue.fromJSON(args[1]));
        break;
      case 'TextInputClient.performAction':
        _currentConnection._client.performAction(_toTextInputAction(args[1]));
        break;
      default:
        throw new MissingPluginException();
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
        SystemChannels.textInput.invokeMethod('TextInput.hide');
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
    SystemChannels.textInput.invokeMethod(
      'TextInput.setClient',
      <dynamic>[ connection._id, configuration.toJSON() ],
    );
    return connection;
  }
}
