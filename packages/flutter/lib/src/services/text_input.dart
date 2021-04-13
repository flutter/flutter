// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show
  FontWeight,
  Offset,
  Size,
  Rect,
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

/// Indicates how to handle the intelligent replacement of dashes in text input.
///
/// See also:
///
///  * [TextField.smartDashesType]
///  * [CupertinoTextField.smartDashesType]
///  * [EditableText.smartDashesType]
///  * [SmartQuotesType]
///  * <https://developer.apple.com/documentation/uikit/uitextinputtraits>
enum SmartDashesType {
  /// Smart dashes is disabled.
  ///
  /// This corresponds to the
  /// ["no" value of UITextSmartDashesType](https://developer.apple.com/documentation/uikit/uitextsmartdashestype/no).
  disabled,

  /// Smart dashes is enabled.
  ///
  /// This corresponds to the
  /// ["yes" value of UITextSmartDashesType](https://developer.apple.com/documentation/uikit/uitextsmartdashestype/yes).
  enabled,
}

/// Indicates how to handle the intelligent replacement of quotes in text input.
///
/// See also:
///
///  * [TextField.smartQuotesType]
///  * [CupertinoTextField.smartQuotesType]
///  * [EditableText.smartQuotesType]
///  * <https://developer.apple.com/documentation/uikit/uitextinputtraits>
enum SmartQuotesType {
  /// Smart quotes is disabled.
  ///
  /// This corresponds to the
  /// ["no" value of UITextSmartQuotesType](https://developer.apple.com/documentation/uikit/uitextsmartquotestype/no).
  disabled,

  /// Smart quotes is enabled.
  ///
  /// This corresponds to the
  /// ["yes" value of UITextSmartQuotesType](https://developer.apple.com/documentation/uikit/uitextsmartquotestype/yes).
  enabled,
}

/// The type of information for which to optimize the text input control.
///
/// On Android, behavior may vary across device and keyboard provider.
///
/// This class stays as close to `Enum` interface as possible, and allows
/// for additional flags for some input types. For example, numeric input
/// can specify whether it supports decimal numbers and/or signed numbers.
@immutable
class TextInputType {
  const TextInputType._(this.index)
    : signed = null,
      decimal = null;

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
  final bool? signed;

  /// The number is decimal, allowing a decimal point to provide fractional.
  ///
  /// This flag is only used for the [number] input type, otherwise `null`.
  /// Use `const TextInputType.numberWithOptions(decimal: true)` to set this.
  final bool? decimal;

  /// Optimize for textual information.
  ///
  /// Requests the default platform keyboard.
  static const TextInputType text = TextInputType._(0);

  /// Optimize for multiline textual information.
  ///
  /// Requests the default platform keyboard, but accepts newlines when the
  /// enter key is pressed. This is the input type used for all multiline text
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

  /// Optimize for passwords that are visible to the user.
  ///
  /// Requests a keyboard with ready access to both letters and numbers.
  static const TextInputType visiblePassword = TextInputType._(7);

  /// Optimized for a person's name.
  ///
  /// On iOS, requests the
  /// [UIKeyboardType.namePhonePad](https://developer.apple.com/documentation/uikit/uikeyboardtype/namephonepad)
  /// keyboard, a keyboard optimized for entering a person’s name or phone number.
  /// Does not support auto-capitalization.
  ///
  /// On Android, requests a keyboard optimized for
  /// [TYPE_TEXT_VARIATION_PERSON_NAME](https://developer.android.com/reference/android/text/InputType#TYPE_TEXT_VARIATION_PERSON_NAME).
  static const TextInputType name = TextInputType._(8);

  /// Optimized for postal mailing addresses.
  ///
  /// On iOS, requests the default keyboard.
  ///
  /// On Android, requests a keyboard optimized for
  /// [TYPE_TEXT_VARIATION_POSTAL_ADDRESS](https://developer.android.com/reference/android/text/InputType#TYPE_TEXT_VARIATION_POSTAL_ADDRESS).
  static const TextInputType streetAddress = TextInputType._(9);

  /// All possible enum values.
  static const List<TextInputType> values = <TextInputType>[
    text, multiline, number, phone, datetime, emailAddress, url, visiblePassword, name, streetAddress,
  ];

  // Corresponding string name for each of the [values].
  static const List<String> _names = <String>[
    'text', 'multiline', 'number', 'phone', 'datetime', 'emailAddress', 'url', 'visiblePassword', 'name', 'address',
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
    return '${objectRuntimeType(this, 'TextInputType')}('
        'name: $_name, '
        'signed: $signed, '
        'decimal: $decimal)';
  }

  @override
  bool operator ==(Object other) {
    return other is TextInputType
        && other.index == index
        && other.signed == signed
        && other.decimal == decimal;
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
/// happen, other than changing the focus when approapriate. It is up to the
/// developer to ensure that the behavior that occurs when an action button is
/// pressed is appropriate for the action button chosen.
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
  /// Moves the focus to the next focusable item in the same [FocusScope].
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
  /// Moves the focus to the previous focusable item in the same [FocusScope].
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
    this.readOnly = false,
    this.obscureText = false,
    this.autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    this.enableSuggestions = true,
    this.actionLabel,
    this.inputAction = TextInputAction.done,
    this.keyboardAppearance = Brightness.light,
    this.textCapitalization = TextCapitalization.none,
    this.autofillConfiguration,
  }) : assert(inputType != null),
       assert(obscureText != null),
       smartDashesType = smartDashesType ?? (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled),
       smartQuotesType = smartQuotesType ?? (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled),
       assert(autocorrect != null),
       assert(enableSuggestions != null),
       assert(keyboardAppearance != null),
       assert(inputAction != null),
       assert(textCapitalization != null);

  /// The type of information for which to optimize the text input control.
  final TextInputType inputType;

  /// Whether the text field can be edited or not.
  ///
  /// Defaults to false.
  final bool readOnly;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true.
  final bool autocorrect;

  /// The configuration to use for autofill.
  ///
  /// Defaults to null, in which case no autofill information will be provided
  /// to the platform. This will prevent the corresponding input field from
  /// participating in autofills triggered by other fields. Additionally, on
  /// Android and web, setting [autofillConfiguration] to null disables autofill.
  final AutofillConfiguration? autofillConfiguration;

  /// {@template flutter.services.TextInputConfiguration.smartDashesType}
  /// Whether to allow the platform to automatically format dashes.
  ///
  /// This flag only affects iOS versions 11 and above. It sets
  /// [`UITextSmartDashesType`](https://developer.apple.com/documentation/uikit/uitextsmartdashestype?language=objc)
  /// in the engine. When true, it passes
  /// [`UITextSmartDashesTypeYes`](https://developer.apple.com/documentation/uikit/uitextsmartdashestype/uitextsmartdashestypeyes?language=objc),
  /// and when false, it passes
  /// [`UITextSmartDashesTypeNo`](https://developer.apple.com/documentation/uikit/uitextsmartdashestype/uitextsmartdashestypeno?language=objc).
  ///
  /// As an example of what this does, two consecutive hyphen characters will be
  /// automatically replaced with one en dash, and three consecutive hyphens
  /// will become one em dash.
  ///
  /// Defaults to true, unless [obscureText] is true, when it defaults to false.
  /// This is to avoid the problem where password fields receive autoformatted
  /// characters.
  ///
  /// See also:
  ///
  ///  * [smartQuotesType]
  ///  * <https://developer.apple.com/documentation/uikit/uitextinputtraits>
  /// {@endtemplate}
  final SmartDashesType smartDashesType;

  /// {@template flutter.services.TextInputConfiguration.smartQuotesType}
  /// Whether to allow the platform to automatically format quotes.
  ///
  /// This flag only affects iOS. It sets
  /// [`UITextSmartQuotesType`](https://developer.apple.com/documentation/uikit/uitextsmartquotestype?language=objc)
  /// in the engine. When true, it passes
  /// [`UITextSmartQuotesTypeYes`](https://developer.apple.com/documentation/uikit/uitextsmartquotestype/uitextsmartquotestypeyes?language=objc),
  /// and when false, it passes
  /// [`UITextSmartQuotesTypeNo`](https://developer.apple.com/documentation/uikit/uitextsmartquotestype/uitextsmartquotestypeno?language=objc).
  ///
  /// As an example of what this does, a standard vertical double quote
  /// character will be automatically replaced by a left or right double quote
  /// depending on its position in a word.
  ///
  /// Defaults to true, unless [obscureText] is true, when it defaults to false.
  /// This is to avoid the problem where password fields receive autoformatted
  /// characters.
  ///
  /// See also:
  ///
  ///  * [smartDashesType]
  ///  * <https://developer.apple.com/documentation/uikit/uitextinputtraits>
  /// {@endtemplate}
  final SmartQuotesType smartQuotesType;

  /// {@template flutter.services.TextInputConfiguration.enableSuggestions}
  /// Whether to show input suggestions as the user types.
  ///
  /// This flag only affects Android. On iOS, suggestions are tied directly to
  /// [autocorrect], so that suggestions are only shown when [autocorrect] is
  /// true. On Android autocorrection and suggestion are controlled separately.
  ///
  /// Defaults to true. Cannot be null.
  ///
  /// See also:
  ///
  ///  * <https://developer.android.com/reference/android/text/InputType.html#TYPE_TEXT_FLAG_NO_SUGGESTIONS>
  /// {@endtemplate}
  final bool enableSuggestions;

  /// What text to display in the text input control's action button.
  final String? actionLabel;

  /// What kind of action to request for the action button on the IME.
  final TextInputAction inputAction;

  /// Specifies how platforms may automatically capitalize text entered by the
  /// user.
  ///
  /// Defaults to [TextCapitalization.none].
  ///
  /// See also:
  ///
  ///  * [TextCapitalization], for a description of each capitalization behavior.
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
      'readOnly': readOnly,
      'obscureText': obscureText,
      'autocorrect': autocorrect,
      'smartDashesType': smartDashesType.index.toString(),
      'smartQuotesType': smartQuotesType.index.toString(),
      'enableSuggestions': enableSuggestions,
      'actionLabel': actionLabel,
      'inputAction': inputAction.toString(),
      'textCapitalization': textCapitalization.toString(),
      'keyboardAppearance': keyboardAppearance.toString(),
      if (autofillConfiguration != null) 'autofill': autofillConfiguration!.toJson(),
    };
  }
}

TextAffinity? _toTextAffinity(String? affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}

/// A floating cursor state the user has induced by force pressing an iOS
/// keyboard.
enum FloatingCursorDragState {
  /// A user has just activated a floating cursor.
  Start,

  /// A user is dragging a floating cursor.
  Update,

  /// A user has lifted their finger off the screen after using a floating
  /// cursor.
  End,
}

/// The current state and position of the floating cursor.
class RawFloatingCursorPoint {
  /// Creates information for setting the position and state of a floating
  /// cursor.
  ///
  /// [state] must not be null and [offset] must not be null if the state is
  /// [FloatingCursorDragState.Update].
  RawFloatingCursorPoint({
    this.offset,
    required this.state,
  }) : assert(state != null),
       assert(state != FloatingCursorDragState.Update || offset != null);

  /// The raw position of the floating cursor as determined by the iOS sdk.
  final Offset? offset;

  /// The state of the floating cursor.
  final FloatingCursorDragState state;
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
    this.composing = TextRange.empty,
  }) : assert(text != null),
       assert(selection != null),
       assert(composing != null);

  /// Creates an instance of this class from a JSON object.
  factory TextEditingValue.fromJSON(Map<String, dynamic> encoded) {
    return TextEditingValue(
      text: encoded['text'] as String,
      selection: TextSelection(
        baseOffset: encoded['selectionBase'] as int? ?? -1,
        extentOffset: encoded['selectionExtent'] as int? ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity'] as String?) ?? TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] as bool? ?? false,
      ),
      composing: TextRange(
        start: encoded['composingBase'] as int? ?? -1,
        end: encoded['composingExtent'] as int? ?? -1,
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
    String? text,
    TextSelection? selection,
    TextRange? composing,
  }) {
    return TextEditingValue(
      text: text ?? this.text,
      selection: selection ?? this.selection,
      composing: composing ?? this.composing,
    );
  }

  /// Whether the [composing] range is a valid range within [text].
  ///
  /// Returns true if and only if the [composing] range is normalized, its start
  /// is greater than or equal to 0, and its end is less than or equal to
  /// [text]'s length.
  ///
  /// If this property is false while the [composing] range's `isValid` is true,
  /// it usually indicates the current [composing] range is invalid because of a
  /// programming error.
  bool get isComposingRangeValid => composing.isValid && composing.isNormalized && composing.end <= text.length;

  @override
  String toString() => '${objectRuntimeType(this, 'TextEditingValue')}(text: \u2524$text\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    return other is TextEditingValue
        && other.text == text
        && other.selection == selection
        && other.composing == composing;
  }

  @override
  int get hashCode => hashValues(
    text.hashCode,
    selection.hashCode,
    composing.hashCode,
  );
}

/// Indicates what triggered the change in selected text (including changes to
/// the cursor location).
enum SelectionChangedCause {
  /// The user tapped on the text and that caused the selection (or the location
  /// of the cursor) to change.
  tap,

  /// The user tapped twice in quick succession on the text and that caused
  /// the selection (or the location of the cursor) to change.
  doubleTap,

  /// The user long-pressed the text and that caused the selection (or the
  /// location of the cursor) to change.
  longPress,

  /// The user force-pressed the text and that caused the selection (or the
  /// location of the cursor) to change.
  forcePress,

  /// The user used the keyboard to change the selection or the location of the
  /// cursor.
  ///
  /// Keyboard-triggered selection changes may be caused by the IME as well as
  /// by accessibility tools (e.g. TalkBack on Android).
  keyboard,

  /// The user used the selection toolbar to change the selection or the
  /// location of the cursor.
  ///
  /// An example is when the user taps on select all in the tool bar.
  toolBar,

  /// The user used the mouse to change the selection by dragging over a piece
  /// of text.
  drag,
}

/// A mixin for manipulating the selection, to be used by the implementer
/// of the toolbar widget.
mixin TextSelectionDelegate {
  /// Gets the current text input.
  TextEditingValue get textEditingValue;

  /// Indicates that the user has requested the delegate to replace its current
  /// text editing state with [value].
  ///
  /// The new [value] is treated as user input and thus may subject to input
  /// formatting.
  @Deprecated(
    'Use the userUpdateTextEditingValue instead. '
    'This feature was deprecated after v1.26.0-17.2.pre.',
  )
  set textEditingValue(TextEditingValue value) {}

  /// Indicates that the user has requested the delegate to replace its current
  /// text editing state with [value].
  ///
  /// The new [value] is treated as user input and thus may subject to input
  /// formatting.
  ///
  /// See also:
  ///
  /// * [EditableTextState.userUpdateTextEditingValue]: an implementation that
  ///   applies additional pre-processing to the specified [value], before
  ///   updating the text editing state.
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause);

  /// Hides the text selection toolbar.
  ///
  /// By default, hideHandles is true, and the toolbar is hidden along with its
  /// handles. If hideHandles is set to false, then the toolbar will be hidden
  /// but the handles will remain.
  void hideToolbar([bool hideHandles = true]);

  /// Brings the provided [TextPosition] into the visible area of the text
  /// input.
  void bringIntoView(TextPosition position);

  /// Whether cut is enabled, must not be null.
  bool get cutEnabled => true;

  /// Whether copy is enabled, must not be null.
  bool get copyEnabled => true;

  /// Whether paste is enabled, must not be null.
  bool get pasteEnabled => true;

  /// Whether select all is enabled, must not be null.
  bool get selectAllEnabled => true;
}

/// An interface to receive information from [TextInput].
///
/// See also:
///
///  * [TextInput.attach]
///  * [EditableText], a [TextInputClient] implementation.
abstract class TextInputClient {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TextInputClient();

  /// The current state of the [TextEditingValue] held by this client.
  TextEditingValue? get currentTextEditingValue;

  /// The [AutofillScope] this [TextInputClient] belongs to, if any.
  ///
  /// It should return null if this [TextInputClient] does not need autofill
  /// support. For a [TextInputClient] that supports autofill, returning null
  /// causes it to participate in autofill alone.
  ///
  /// See also:
  ///
  /// * [AutofillGroup], a widget that creates an [AutofillScope] for its
  ///   descendent autofillable [TextInputClient]s.
  AutofillScope? get currentAutofillScope;

  /// Requests that this client update its editing state to the given value.
  ///
  /// The new [value] is treated as user input and thus may subject to input
  /// formatting.
  void updateEditingValue(TextEditingValue value);

  /// Requests that this client perform the given action.
  void performAction(TextInputAction action);

  /// Request from the input method that this client perform the given private
  /// command.
  ///
  /// This can be used to provide domain-specific features that are only known
  /// between certain input methods and their clients.
  ///
  /// See also:
  ///   * [https://developer.android.com/reference/android/view/inputmethod/InputConnection#performPrivateCommand(java.lang.String,%20android.os.Bundle)],
  ///     which is the Android documentation for performPrivateCommand, used to
  ///     send a command from the input method.
  ///   * [https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#sendAppPrivateCommand],
  ///     which is the Android documentation for sendAppPrivateCommand, used to
  ///     send a command to the input method.
  void performPrivateCommand(String action, Map<String, dynamic> data);

  /// Updates the floating cursor position and state.
  void updateFloatingCursor(RawFloatingCursorPoint point);

  /// Requests that this client display a prompt rectangle for the given text range,
  /// to indicate the range of text that will be changed by a pending autocorrection.
  ///
  /// This method will only be called on iOS.
  void showAutocorrectionPromptRect(int start, int end);

  /// Platform notified framework of closed connection.
  ///
  /// [TextInputClient] should cleanup its connection and finalize editing.
  void connectionClosed();
}

/// An interface for interacting with a text input control.
///
/// See also:
///
///  * [TextInput.attach], a method used to establish a [TextInputConnection]
///    between the system's text input and a [TextInputClient].
///  * [EditableText], a [TextInputClient] that connects to and interacts with
///    the system's text input using a [TextInputConnection].
class TextInputConnection {
  TextInputConnection._(this._client)
      : assert(_client != null),
        _id = _nextId++;

  Size? _cachedSize;
  Matrix4? _cachedTransform;
  Rect? _cachedRect;
  Rect? _cachedCaretRect;

  static int _nextId = 1;
  final int _id;

  /// Resets the internal ID counter for testing purposes.
  ///
  /// This call has no effect when asserts are disabled. Calling it from
  /// application code will likely break text input for the application.
  @visibleForTesting
  static void debugResetId({int to = 1}) {
    assert(to != null);
    assert(() {
      _nextId = to;
      return true;
    }());
  }

  final TextInputClient _client;

  /// Whether this connection is currently interacting with the text input control.
  bool get attached => TextInput._instance._currentConnection == this;

  /// Requests that the text input control become visible.
  void show() {
    assert(attached);
    TextInput._instance._show();
  }

  /// Requests the system autofill UI to appear.
  ///
  /// Currently only works on Android. Other platforms do not respond to this
  /// message.
  ///
  /// See also:
  ///
  ///  * [EditableText], a [TextInputClient] that calls this method when focused.
  void requestAutofill() {
    assert(attached);
    TextInput._instance._requestAutofill();
  }

  /// Requests that the text input control update itself according to the new
  /// [TextInputConfiguration].
  void updateConfig(TextInputConfiguration configuration) {
    assert(attached);
    TextInput._instance._updateConfig(configuration);
  }

  /// Requests that the text input control change its internal state to match
  /// the given state.
  void setEditingState(TextEditingValue value) {
    assert(attached);
    TextInput._instance._setEditingState(value);
  }

  /// Send the size and transform of the editable text to engine.
  ///
  /// The values are sent as platform messages so they can be used on web for
  /// example to correctly position and size the html input field.
  ///
  /// 1. [editableBoxSize]: size of the render editable box.
  ///
  /// 2. [transform]: a matrix that maps the local paint coordinate system
  ///                 to the [PipelineOwner.rootNode].
  void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform) {
    if (editableBoxSize != _cachedSize || transform != _cachedTransform) {
      _cachedSize = editableBoxSize;
      _cachedTransform = transform;
      TextInput._instance._setEditableSizeAndTransform(
        <String, dynamic>{
          'width': editableBoxSize.width,
          'height': editableBoxSize.height,
          'transform': transform.storage,
        },
      );
    }
  }

  /// Send the smallest rect that covers the text in the client that's currently
  /// being composed.
  ///
  /// The given `rect` can not be null. If any of the 4 coordinates of the given
  /// [Rect] is not finite, a [Rect] of size (-1, -1) will be sent instead.
  ///
  /// This information is used for positioning the IME candidates menu on each
  /// platform.
  void setComposingRect(Rect rect) {
    assert(rect != null);
    if (rect == _cachedRect)
      return;
    _cachedRect = rect;
    final Rect validRect = rect.isFinite ? rect : Offset.zero & const Size(-1, -1);
    TextInput._instance._setComposingTextRect(
      <String, dynamic>{
        'width': validRect.width,
        'height': validRect.height,
        'x': validRect.left,
        'y': validRect.top,
      },
    );
  }

  /// Sends the coordinates of caret rect. This is used on macOS for positioning
  /// the accent selection menu.
  void setCaretRect(Rect rect) {
    assert(rect != null);
    if (rect == _cachedCaretRect)
      return;
    _cachedCaretRect = rect;
    final Rect validRect = rect.isFinite ? rect : Offset.zero & const Size(-1, -1);
    TextInput._instance._setCaretRect(
      <String, dynamic>{
        'width': validRect.width,
        'height': validRect.height,
        'x': validRect.left,
        'y': validRect.top,
      },
    );
  }

  /// Send text styling information.
  ///
  /// This information is used by the Flutter Web Engine to change the style
  /// of the hidden native input's content. Hence, the content size will match
  /// to the size of the editable widget's content.
  void setStyle({
    required String? fontFamily,
    required double? fontSize,
    required FontWeight? fontWeight,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    assert(attached);

    TextInput._instance._setStyle(
      <String, dynamic>{
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeightIndex': fontWeight?.index,
        'textAlignIndex': textAlign.index,
        'textDirectionIndex': textDirection.index,
      },
    );
  }

  /// Stop interacting with the text input control.
  ///
  /// After calling this method, the text input control might disappear if no
  /// other client attaches to it within this animation frame.
  void close() {
    if (attached) {
      TextInput._instance._clearClient();
    }
    assert(!attached);
  }

  /// Platform sent a notification informing the connection is closed.
  ///
  /// [TextInputConnection] should clean current client connection.
  void connectionClosedReceived() {
    TextInput._instance._currentConnection = null;
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
    case 'TextInputAction.previous':
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
  throw FlutterError.fromParts(<DiagnosticsNode>[ErrorSummary('Unknown text input action: $action')]);
}

FloatingCursorDragState _toTextCursorAction(String state) {
  switch (state) {
    case 'FloatingCursorDragState.start':
      return FloatingCursorDragState.Start;
    case 'FloatingCursorDragState.update':
      return FloatingCursorDragState.Update;
    case 'FloatingCursorDragState.end':
      return FloatingCursorDragState.End;
  }
  throw FlutterError.fromParts(<DiagnosticsNode>[ErrorSummary('Unknown text cursor action: $state')]);
}

RawFloatingCursorPoint _toTextPoint(FloatingCursorDragState state, Map<String, dynamic> encoded) {
  assert(state != null, 'You must provide a state to set a new editing point.');
  assert(encoded['X'] != null, 'You must provide a value for the horizontal location of the floating cursor.');
  assert(encoded['Y'] != null, 'You must provide a value for the vertical location of the floating cursor.');
  final Offset offset = state == FloatingCursorDragState.Update
    ? Offset(encoded['X'] as double, encoded['Y'] as double)
    : Offset.zero;
  return RawFloatingCursorPoint(offset: offset, state: state);
}

/// An low-level interface to the system's text input control.
///
/// To start interacting with the system's text input control, call [attach] to
/// establish a [TextInputConnection] between the system's text input control
/// and a [TextInputClient]. The majority of commands available for
/// interacting with the text input control reside in the returned
/// [TextInputConnection]. The communication between the system text input and
/// the [TextInputClient] is asynchronous.
///
/// The platform text input plugin (which represents the system's text input)
/// and the [TextInputClient] usually maintain their own text editing states
/// ([TextEditingValue]) separately. They must be kept in sync as long as the
/// [TextInputClient] is connected. The following methods can be used to send
/// [TextEditingValue] to update the other party, when either party's text
/// editing states change:
///
/// * The [TextInput.attach] method allows a [TextInputClient] to establish a
///   connection to the text input. An optional field in its `configuration`
///   parameter can be used to specify an initial value for the platform text
///   input plugin's [TextEditingValue].
///
/// * The [TextInputClient] sends its [TextEditingValue] to the platform text
///   input plugin using [TextInputConnection.setEditingState].
///
/// * The platform text input plugin sends its [TextEditingValue] to the
///   connected [TextInputClient] via a "TextInput.setEditingState" message.
///
/// * When autofill happens on a disconnected [TextInputClient], the platform
///   text input plugin sends the [TextEditingValue] to the connected
///   [TextInputClient]'s [AutofillScope], and the [AutofillScope] will further
///   relay the value to the correct [TextInputClient].
///
/// When synchronizing the [TextEditingValue]s, the communication may get stuck
/// in an infinite when both parties are trying to send their own update. To
/// mitigate the problem, only [TextInputClient]s are allowed to alter the
/// received [TextEditingValue]s while platform text input plugins are to accept
/// the received [TextEditingValue]s unmodified. More specifically:
///
/// * When a [TextInputClient] receives a new [TextEditingValue] from the
///   platform text input plugin, it's allowed to modify the value (for example,
///   apply [TextInputFormatter]s). If it decides to do so, it must send the
///   updated [TextEditingValue] back to the platform text input plugin to keep
///   the [TextEditingValue]s in sync.
///
/// * When the platform text input plugin receives a new value from the
///   connected [TextInputClient], it must accept the new value as-is, to avoid
///   sending back an updated value.
///
/// See also:
///
///  * [TextField], a widget in which the user may enter text.
///  * [EditableText], a [TextInputClient] that connects to [TextInput] when it
///    wants to take user input from the keyboard.
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

  late MethodChannel _channel;

  TextInputConnection? _currentConnection;
  late TextInputConfiguration _currentConfiguration;

  Future<dynamic> _handleTextInputInvocation(MethodCall methodCall) async {
    if (_currentConnection == null)
      return;
    final String method = methodCall.method;

    // The requestExistingInputState request needs to be handled regardless of
    // the client ID, as long as we have a _currentConnection.
    if (method == 'TextInputClient.requestExistingInputState') {
      assert(_currentConnection!._client != null);
      _attach(_currentConnection!, _currentConfiguration);
      final TextEditingValue? editingValue = _currentConnection!._client.currentTextEditingValue;
      if (editingValue != null) {
        _setEditingState(editingValue);
      }
      return;
    }

    final List<dynamic> args = methodCall.arguments as List<dynamic>;

    if (method == 'TextInputClient.updateEditingStateWithTag') {
      final TextInputClient client = _currentConnection!._client;
      assert(client != null);
      final AutofillScope? scope = client.currentAutofillScope;
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
    if (client != _currentConnection!._id)
      return;
    switch (method) {
      case 'TextInputClient.updateEditingState':
        _currentConnection!._client.updateEditingValue(TextEditingValue.fromJSON(args[1] as Map<String, dynamic>));
        break;
      case 'TextInputClient.performAction':
        _currentConnection!._client.performAction(_toTextInputAction(args[1] as String));
        break;
      case 'TextInputClient.performPrivateCommand':
        _currentConnection!._client.performPrivateCommand(
          args[1]['action'] as String, args[1]['data'] as Map<String, dynamic>,
        );
        break;
      case 'TextInputClient.updateFloatingCursor':
        _currentConnection!._client.updateFloatingCursor(_toTextPoint(
          _toTextCursorAction(args[1] as String),
          args[2] as Map<String, dynamic>,
        ));
        break;
      case 'TextInputClient.onConnectionClosed':
        _currentConnection!._client.connectionClosed();
        break;
      case 'TextInputClient.showAutocorrectionPromptRect':
        _currentConnection!._client.showAutocorrectionPromptRect(args[1] as int, args[2] as int);
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

  void _updateConfig(TextInputConfiguration configuration) {
    assert(configuration != null);
    _channel.invokeMethod<void>(
      'TextInput.updateConfig',
      configuration.toJson(),
    );
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

  void _setComposingTextRect(Map<String, dynamic> args) {
    _channel.invokeMethod<void>(
      'TextInput.setMarkedTextRect',
      args,
    );
  }

  void _setCaretRect(Map<String, dynamic> args) {
    _channel.invokeMethod<void>(
      'TextInput.setCaretRect',
      args,
    );
  }

  void _setStyle(Map<String, dynamic> args) {
    _channel.invokeMethod<void>(
      'TextInput.setStyle',
      args,
    );
  }

  /// Finishes the current autofill context, and potentially saves the user
  /// input for future use if `shouldSave` is true.
  ///
  /// Typically, this method should be called when the user has finalized their
  /// input. For example, in a [Form], it's typically done immediately before or
  /// after its content is submitted.
  ///
  /// The topmost [AutofillGroup]s also call [finishAutofillContext]
  /// automatically when they are disposed. The default behavior can be
  /// overridden in [AutofillGroup.onDisposeAction].
  ///
  /// {@template flutter.services.TextInput.finishAutofillContext}
  /// An autofill context is a collection of input fields that live in the
  /// platform's text input plugin. The platform is encouraged to save the user
  /// input stored in the current autofill context before the context is
  /// destroyed, when [TextInput.finishAutofillContext] is called with
  /// `shouldSave` set to true.
  ///
  /// Currently, there can only be at most one autofill context at any given
  /// time. When any input field in an [AutofillGroup] requests for autofill
  /// (which is done automatically when an autofillable [EditableText] gains
  /// focus), the current autofill context will merge the content of that
  /// [AutofillGroup] into itself. When there isn't an existing autofill context,
  /// one will be created to hold the newly added input fields from the group.
  ///
  /// Once added to an autofill context, an input field will stay in the context
  /// until the context is destroyed. To prevent leaks, call
  /// [TextInput.finishAutofillContext] to signal the text input plugin that the
  /// user has finalized their input in the current autofill context. The
  /// platform text input plugin either encourages or discourages the platform
  /// from saving the user input based on the value of the `shouldSave`
  /// parameter. The platform usually shows a "Save for autofill?" prompt for
  /// user confirmation.
  /// {@endtemplate}
  ///
  /// On many platforms, calling [finishAutofillContext] shows the save user
  /// input dialog and disrupts the user's flow. Ideally the dialog should only
  /// be shown no more than once for every screen. Consider removing premature
  /// [finishAutofillContext] calls to prevent showing the save user input UI
  /// too frequently. However, calling [finishAutofillContext] when there's no
  /// existing autofill context usually does not bring up the save user input
  /// UI.
  ///
  /// See also:
  ///
  /// * [EditableText.autofillHints] for autofill save troubleshooting tips.
  /// * [AutofillGroup.onDisposeAction], a configurable action that runs when a
  ///   topmost [AutofillGroup] is getting disposed.
  static void finishAutofillContext({ bool shouldSave = true }) {
    assert(shouldSave != null);
    TextInput._instance._channel.invokeMethod<void>(
      'TextInput.finishAutofillContext',
      shouldSave ,
    );
  }
}
