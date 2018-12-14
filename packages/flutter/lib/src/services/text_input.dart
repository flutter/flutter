// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show TextAffinity, hashValues;

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'system_channels.dart';
import 'system_chrome.dart';
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

  /// Optimize for numerical information.
  ///
  /// Requests a numeric keyboard with additional settings.
  /// The [signed] and [decimal] parameters are optional.
  const TextInputType.numberWithOptions({
    this.signed = false,
    this.decimal = false,
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
  static const TextInputType text = TextInputType._(0);

  /// Optimize for multi-line textual information.
  ///
  /// Requests the default platform keyboard, but accepts newlines when the
  /// enter key is pressed. This is the input type used for all multi-line text
  /// fields.
  static const TextInputType multiline = TextInputType._(1);

  /// Optimize for unsigned numerical information without a decimal point.
  ///
  /// Requests a default keyboard with ready access to the number keys.
  /// Additional options, such as decimal point and/or positive/negative
  /// signs, can be requested using [new TextInputType.numberWithOptions].
  static const TextInputType number = TextInputType.numberWithOptions();

  /// Optimize for telephone numbers.
  ///
  /// Requests a keyboard with ready access to the number keys, "*", and "#".
  static const TextInputType phone = TextInputType._(3);

  /// Optimize for date and time information.
  ///
  /// On iOS, requests the default keyboard.
  ///
  /// On Android, requests a keyboard with ready access to the number keys,
  /// ":", and "-".
  static const TextInputType datetime = TextInputType._(4);

  /// Optimize for email addresses.
  ///
  /// Requests a keyboard with ready access to the "@" and "." keys.
  static const TextInputType emailAddress = TextInputType._(5);

  /// Optimize for URLs.
  ///
  /// Requests a keyboard with ready access to the "/" and "." keys.
  static const TextInputType url = TextInputType._(6);

  /// All possible enum values.
  static const List<TextInputType> values = <TextInputType>[
    text, multiline, number, phone, datetime, emailAddress, url,
  ];

  // Corresponding string name for each of the [values].
  static const List<String> _names = <String>[
    'text', 'multiline', 'number', 'phone', 'datetime', 'emailAddress', 'url',
  ];

  // Enum value name, this is what enum.toString() would normally return.
  String get _name => 'TextInputType.${_names[index]}';

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJson() {
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
///
/// Each action represents a logical meaning, and also configures the soft
/// keyboard to display a certain kind of action button. The visual appearance
/// of the action button might differ between versions of the same OS.
///
/// Despite the logical meaning of each action, choosing a particular
/// [TextInputAction] does not necessarily cause any specific behavior to
/// happen. It is up to the developer to ensure that the behavior that occurs
/// when an action button is pressed is appropriate for the action button chosen.
///
/// For example: If the user presses the keyboard action button on iOS when it
/// reads "Emergency Call", the result should not be a focus change to the next
/// TextField. This behavior is not logically appropriate for a button that says
/// "Emergency Call".
///
/// See [EditableText] for more information about customizing action button
/// behavior.
///
/// Most [TextInputAction]s are supported equally by both Android and iOS.
/// However, there is not a complete, direct mapping between Android's IME input
/// types and iOS's keyboard return types. Therefore, some [TextInputAction]s
/// are inappropriate for one of the platforms. If a developer chooses an
/// inappropriate [TextInputAction] when running in debug mode, an error will be
/// thrown. If the same thing is done in release mode, then instead of sending
/// the inappropriate value, Android will use "unspecified" on the platform
/// side and iOS will use "default" on the platform side.
///
/// See also:
///
///  * [TextInput], which configures the platform's keyboard setup.
///  * [EditableText], which invokes callbacks when the action button is pressed.
enum TextInputAction {
  /// Logical meaning: There is no relevant input action for the current input
  /// source, e.g., [TextField].
  ///
  /// Android: Corresponds to Android's "IME_ACTION_NONE". The keyboard setup
  /// is decided by the OS. The keyboard will likely show a return key.
  ///
  /// iOS: iOS does not have a keyboard return type of "none." It is
  /// inappropriate to choose this [TextInputAction] when running on iOS.
  none,

  /// Logical meaning: Let the OS decide which action is most appropriate.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_UNSPECIFIED". The OS chooses
  /// which keyboard action to display. The decision will likely be a done
  /// button or a return key.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyDefault". The title displayed in
  /// the action button is "return".
  unspecified,

  /// Logical meaning: The user is done providing input to a group of inputs
  /// (like a form). Some kind of finalization behavior should now take place.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_DONE". The OS displays a
  /// button that represents completion, e.g., a checkmark button.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyDone". The title displayed in the
  /// action button is "Done".
  done,

  /// Logical meaning: The user has entered some text that represents a
  /// destination, e.g., a restaurant name. The "go" button is intended to take
  /// the user to a part of the app that corresponds to this destination.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_GO". The OS displays a
  /// button that represents taking "the user to the target of the text they
  /// typed", e.g., a right-facing arrow button.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyGo". The title displayed in the
  /// action button is "Go".
  go,

  /// Logical meaning: Execute a search query.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_SEARCH". The OS displays a
  /// button that represents a search, e.g., a magnifying glass button.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeySearch". The title displayed in the
  /// action button is "Search".
  search,

  /// Logical meaning: Sends something that the user has composed, e.g., an
  /// email or a text message.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_SEND". The OS displays a
  /// button that represents sending something, e.g., a paper plane button.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeySend". The title displayed in the
  /// action button is "Send".
  send,

  /// Logical meaning: The user is done with the current input source and wants
  /// to move to the next one.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_NEXT". The OS displays a
  /// button that represents moving forward, e.g., a right-facing arrow button.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyNext". The title displayed in the
  /// action button is "Next".
  next,

  /// Logical meaning: The user wishes to return to the previous input source
  /// in the group, e.g., a form with multiple [TextField]s.
  ///
  /// Android: Corresponds to Android's "IME_ACTION_PREVIOUS". The OS displays a
  /// button that represents moving backward, e.g., a left-facing arrow button.
  ///
  /// iOS: iOS does not have a keyboard return type of "previous." It is
  /// inappropriate to choose this [TextInputAction] when running on iOS.
  previous,

  /// Logical meaning: In iOS apps, it is common for a "Back" button and
  /// "Continue" button to appear at the top of the screen. However, when the
  /// keyboard is open, these buttons are often hidden off-screen. Therefore,
  /// the purpose of the "Continue" return key on iOS is to make the "Continue"
  /// button available when the user is entering text.
  ///
  /// Historical context aside, [TextInputAction.continueAction] can be used any
  /// time that the term "Continue" seems most appropriate for the given action.
  ///
  /// Android: Android does not have an IME input type of "continue." It is
  /// inappropriate to choose this [TextInputAction] when running on Android.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyContinue". The title displayed in the
  /// action button is "Continue". This action is only available on iOS 9.0+.
  ///
  /// The reason that this value has "Action" post-fixed to it is because
  /// "continue" is a reserved word in Dart, as well as many other languages.
  continueAction,

  /// Logical meaning: The user wants to join something, e.g., a wireless
  /// network.
  ///
  /// Android: Android does not have an IME input type of "join." It is
  /// inappropriate to choose this [TextInputAction] when running on Android.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyJoin". The title displayed in the
  /// action button is "Join".
  join,

  /// Logical meaning: The user wants routing options, e.g., driving directions.
  ///
  /// Android: Android does not have an IME input type of "route." It is
  /// inappropriate to choose this [TextInputAction] when running on Android.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyRoute". The title displayed in the
  /// action button is "Route".
  route,

  /// Logical meaning: Initiate a call to emergency services.
  ///
  /// Android: Android does not have an IME input type of "emergencyCall." It is
  /// inappropriate to choose this [TextInputAction] when running on Android.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyEmergencyCall". The title displayed
  /// in the action button is "Emergency Call".
  emergencyCall,

  /// Logical meaning: Insert a newline character in the focused text input,
  /// e.g., [TextField].
  ///
  /// Android: Corresponds to Android's "IME_ACTION_NONE". The OS displays a
  /// button that represents a new line, e.g., a carriage return button.
  ///
  /// iOS: Corresponds to iOS's "UIReturnKeyDefault". The title displayed in the
  /// action button is "return".
  ///
  /// The term [TextInputAction.newline] exists in Flutter but not in Android
  /// or iOS. The reason for introducing this term is so that developers can
  /// achieve the common result of inserting new lines without needing to
  /// understand the various IME actions on Android and return keys on iOS.
  /// Thus, [TextInputAction.newline] is a convenience term that alleviates the
  /// need to understand the underlying platforms to achieve this common behavior.
  newline,
}

/// Configures how the platform keyboard will select an uppercase or
/// lowercase keyboard.
///
/// Only supports text keyboards, other keyboard types will ignore this
/// configuration. Capitalization is locale-aware.
enum TextCapitalization {
  /// Defaults to an uppercase keyboard for the first letter of each word.
  ///
  /// Corresponds to `InputType.TYPE_TEXT_FLAG_CAP_WORDS` on Android, and
  /// `UITextAutocapitalizationTypeWords` on iOS.
  words,

  /// Defaults to an uppercase keyboard for the first letter of each sentence.
  ///
  /// Corresponds to `InputType.TYPE_TEXT_FLAG_CAP_SENTENCES` on Android, and
  /// `UITextAutocapitalizationTypeSentences` on iOS.
  sentences,

  /// Defaults to an uppercase keyboard for each character.
  ///
  /// Corresponds to `InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS` on Android, and
  /// `UITextAutocapitalizationTypeAllCharacters` on iOS.
  characters,

  /// Defaults to a lowercase keyboard.
  none,
}

/// Controls the visual appearance of the text input control.
///
/// Many [TextInputAction]s are common between Android and iOS. However, if an
/// [inputAction] is provided that is not supported by the current
/// platform in debug mode, an error will be thrown when the corresponding
/// text input is attached. For example, providing iOS's "emergencyCall"
/// action when running on an Android device will result in an error when in
/// debug mode. In release mode, incompatible [TextInputAction]s are replaced
/// either with "unspecified" on Android, or "default" on iOS. Appropriate
/// [inputAction]s can be chosen by checking the current platform and then
/// selecting the appropriate action.
///
/// See also:
///
///  * [TextInput.attach]
///  * [TextInputAction]
@immutable
class TextInputConfiguration {
  /// Creates configuration information for a text input control.
  ///
  /// All arguments have default values, except [actionLabel]. Only
  /// [actionLabel] may be null.
  const TextInputConfiguration({
    this.inputType = TextInputType.text,
    this.obscureText = false,
    this.autocorrect = true,
    this.actionLabel,
    this.inputAction = TextInputAction.done,
    this.keyboardAppearance = Brightness.light,
    this.textCapitalization = TextCapitalization.none,
  }) : assert(inputType != null),
       assert(obscureText != null),
       assert(autocorrect != null),
       assert(keyboardAppearance != null),
       assert(inputAction != null),
       assert(textCapitalization != null);

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

  /// Specifies how platforms may automatically capitialize text entered by the
  /// user.
  ///
  /// Defaults to [TextCapitalization.none].
  ///
  /// See also:
  ///
  ///   * [TextCapitalization], for a description of each capitalization behavior.
  final TextCapitalization textCapitalization;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inputType': inputType.toJson(),
      'obscureText': obscureText,
      'autocorrect': autocorrect,
      'actionLabel': actionLabel,
      'inputAction': inputAction.toString(),
      'textCapitalization': textCapitalization.toString(),
      'keyboardAppearance': keyboardAppearance.toString(),
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
    this.text = '',
    this.selection = const TextSelection.collapsed(offset: -1),
    this.composing = TextRange.empty
  }) : assert(text != null),
       assert(selection != null),
       assert(composing != null);

  /// Creates an instance of this class from a JSON object.
  factory TextEditingValue.fromJSON(Map<String, dynamic> encoded) {
    return TextEditingValue(
      text: encoded['text'],
      selection: TextSelection(
        baseOffset: encoded['selectionBase'] ?? -1,
        extentOffset: encoded['selectionExtent'] ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity']) ?? TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] ?? false,
      ),
      composing: TextRange(
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
  static const TextEditingValue empty = TextEditingValue();

  /// Creates a copy of this value but with the given fields replaced with the new values.
  TextEditingValue copyWith({
    String text,
    TextSelection selection,
    TextRange composing
  }) {
    return TextEditingValue(
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

/// An interface for manipulating the selection, to be used by the implementor
/// of the toolbar widget.
abstract class TextSelectionDelegate {
  /// Gets the current text input.
  TextEditingValue get textEditingValue;

  /// Sets the current text input (replaces the whole line).
  set textEditingValue(TextEditingValue value);

  /// Hides the text selection toolbar.
  void hideToolbar();

  /// Brings the provided [TextPosition] into the visible area of the text
  /// input.
  void bringIntoView(TextPosition position);
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
    case 'TextInputAction.none':
      return TextInputAction.none;
    case 'TextInputAction.unspecified':
      return TextInputAction.unspecified;
    case 'TextInputAction.go':
      return TextInputAction.go;
    case 'TextInputAction.search':
      return TextInputAction.search;
    case 'TextInputAction.send':
      return TextInputAction.send;
    case 'TextInputAction.next':
      return TextInputAction.next;
    case 'TextInputAction.previuos':
      return TextInputAction.previous;
    case 'TextInputAction.continue_action':
      return TextInputAction.continueAction;
    case 'TextInputAction.join':
      return TextInputAction.join;
    case 'TextInputAction.route':
      return TextInputAction.route;
    case 'TextInputAction.emergencyCall':
      return TextInputAction.emergencyCall;
    case 'TextInputAction.done':
      return TextInputAction.done;
    case 'TextInputAction.newline':
      return TextInputAction.newline;
  }
  throw FlutterError('Unknown text input action: $action');
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
        _currentConnection._client.updateEditingValue(TextEditingValue.fromJSON(args[1]));
        break;
      case 'TextInputClient.performAction':
        _currentConnection._client.performAction(_toTextInputAction(args[1]));
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
        SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }
}

final _TextInputClientHandler _clientHandler = _TextInputClientHandler();

/// An interface to the system's text input control.
class TextInput {
  TextInput._();

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
    assert(_debugEnsureInputActionWorksOnPlatform(configuration.inputAction));
    final TextInputConnection connection = TextInputConnection._(client);
    _clientHandler._currentConnection = connection;
    SystemChannels.textInput.invokeMethod(
      'TextInput.setClient',
      <dynamic>[ connection._id, configuration.toJson() ],
    );
    return connection;
  }

  static bool _debugEnsureInputActionWorksOnPlatform(TextInputAction inputAction) {
    assert(() {
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
}
