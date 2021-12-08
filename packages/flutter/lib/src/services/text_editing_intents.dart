// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'intents.dart';

/// An [Intent] to send the input event straight to the engine.
///
/// This [Intent] is currently used by [DefaultTextEditingShortcuts] to indicate
/// the key events that was bound to a particular shortcut should be handled
/// by the platform's text input system, instead of the Flutter framework.
///
/// See also:
///
///   * [DefaultTextEditingShortcuts], which triggers this [Intent].
class DoNothingAndStopPropagationTextIntent extends Intent {
  /// Creates an instance of [DoNothingAndStopPropagationTextIntent].
  const DoNothingAndStopPropagationTextIntent();
}

/// An [Intent] representing an unrecognized text input command sent by the
/// platform's text input plugin.
///
/// {@template flutter.services.textEditingIntents.privateCommands}
/// Some input method editors (IMEs) may define "private" commands to implement
/// domain-specific features that are only known between certain input methods
/// and their clients.
///
/// For instance, on Android, the IME can send app-private commands via
/// [`InputConnection.performPrivateCommand`](https://developer.android.com/reference/android/view/inputmethod/InputConnection#performPrivateCommand(java.lang.String,%20android.os.Bundle)),
/// and on macOS input fields receives "dynamic" commands in the form of selectors:
/// [`-[NSTextInputClient doCommandBySelector:]`](https://developer.apple.com/documentation/appkit/nstextinputclient/1438256-docommand).
/// {@endtemplate}
class PerformPrivateTextInputCommandIntent extends Intent {
  /// Creates a [PerformPrivateTextInputCommandIntent], using the unrecognized
  /// [TextInput] [MethodCall].
  const PerformPrivateTextInputCommandIntent(this.methodCall);

  /// The [methodCall] that isn't recognized by [IntentTextInputConnection].
  final MethodCall methodCall;
}

/// A text editing related [Intent] that performs an operation towards a given
/// direction of the current caret location.
abstract class DirectionalTextEditingIntent extends Intent {
  /// Creates a [DirectionalTextEditingIntent].
  const DirectionalTextEditingIntent(this.forward);

  /// Whether the input field, if applicable, should perform the text editing
  /// operation from the current caret location towards the end of the document.
  ///
  /// Unless otherwise specified by the recipient of this intent, this parameter
  /// uses the logical order of characters in the string to determind the
  /// direction, and is not affected by the writing direction of the text.
  final bool forward;
}

/// Deletes the character before or after the caret location, based on whether
/// `forward` is true.
///
/// {@template flutter.widgets.TextEditingIntents.logicalOrder}
/// {@endtemplate}
///
/// Typically a text field will not respond to this intent if it has no active
/// caret ([TextSelection.isValid] is false for the current selection).
class DeleteCharacterIntent extends DirectionalTextEditingIntent {
  /// Creates a [DeleteCharacterIntent].
  const DeleteCharacterIntent({ required bool forward }) : super(forward);
}

/// Deletes from the current caret location to the previous or next word
/// boundary, based on whether `forward` is true.
class DeleteToNextWordBoundaryIntent extends DirectionalTextEditingIntent {
  /// Creates a [DeleteToNextWordBoundaryIntent].
  const DeleteToNextWordBoundaryIntent({ required bool forward }) : super(forward);
}

/// Deletes from the current caret location to the previous or next soft or hard
/// line break, based on whether `forward` is true.
class DeleteToLineBreakIntent extends DirectionalTextEditingIntent {
  /// Creates a [DeleteToLineBreakIntent].
  const DeleteToLineBreakIntent({ required bool forward }) : super(forward);
}

/// A [DirectionalTextEditingIntent] that moves the caret or the selection to a
/// new location.
abstract class DirectionalCaretMovementIntent extends DirectionalTextEditingIntent {
  /// Creates a [DirectionalCaretMovementIntent].
  const DirectionalCaretMovementIntent(
    bool forward,
    this.collapseSelection,
    [this.collapseAtReversal = false]
  ) : assert(!collapseSelection || !collapseAtReversal),
      super(forward);

  /// Whether this [Intent] should make the selection collapsed (so it becomes a
  /// caret), after the movement.
  ///
  /// When [collapseSelection] is false, the input field typically only moves
  /// the current [TextSelection.extent] to the new location, while maintains
  /// the current [TextSelection.base] location.
  ///
  /// When [collapseSelection] is true, the input field typically should move
  /// both the [TextSelection.base] and the [TextSelection.extent] to the new
  /// location.
  final bool collapseSelection;

  /// Whether to collapse the selection when it would otherwise reverse order.
  ///
  /// For example, consider when forward is true and the extent is before the
  /// base. If collapseAtReversal is true, then this will cause the selection to
  /// collapse at the base. If it's false, then the extent will be placed at the
  /// linebreak, reversing the order of base and offset.
  ///
  /// Cannot be true when collapseSelection is true.
  final bool collapseAtReversal;
}

/// Expands, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next character
/// boundary.
class ExtendSelectionByCharacterIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionByCharacterIntent].
  const ExtendSelectionByCharacterIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Expands, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next word
/// boundary.
class ExtendSelectionToNextWordBoundaryIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionToNextWordBoundaryIntent].
  const ExtendSelectionToNextWordBoundaryIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Expands, or moves the current selection from the current
/// [TextSelection.extent] position to the previous or the next word
/// boundary, or the [TextSelection.base] position if it's closer in the move
/// direction.
///
/// This [Intent] typically has the same effect as an
/// [ExtendSelectionToNextWordBoundaryIntent], except it collapses the selection
/// when the order of [TextSelection.base] and [TextSelection.extent] would
/// reverse.
///
/// This is typically only used on macOS.
class ExtendSelectionToNextWordBoundaryOrCaretLocationIntent extends DirectionalTextEditingIntent {
  /// Creates an [ExtendSelectionToNextWordBoundaryOrCaretLocationIntent].
  const ExtendSelectionToNextWordBoundaryOrCaretLocationIntent({
    required bool forward,
  }) : super(forward);
}

/// Expands, or moves the current selection from the current
/// [TextSelection.extent] position to the closest line break in the direction
/// given by [forward].
class ExtendSelectionToLineBreakIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionToLineBreakIntent].
  const ExtendSelectionToLineBreakIntent({
    required bool forward,
    required bool collapseSelection,
    bool collapseAtReversal = false,
  }) : assert(!collapseSelection || !collapseAtReversal),
       super(forward, collapseSelection, collapseAtReversal);
}

/// Expands, or moves the current selection from the current
/// [TextSelection.extent] position to the closest position on the adjacent
/// line.
class ExtendSelectionVerticallyToAdjacentLineIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionVerticallyToAdjacentLineIntent].
  const ExtendSelectionVerticallyToAdjacentLineIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// Expands, or moves the current selection from the current
/// [TextSelection.extent] position to the start or the end of the document.
class ExtendSelectionToDocumentBoundaryIntent extends DirectionalCaretMovementIntent {
  /// Creates an [ExtendSelectionToDocumentBoundaryIntent].
  const ExtendSelectionToDocumentBoundaryIntent({
    required bool forward,
    required bool collapseSelection,
  }) : super(forward, collapseSelection);
}

/// An [Intent] to select everything in the field.
class SelectAllTextIntent extends Intent {
  /// Creates an instance of [SelectAllTextIntent].
  const SelectAllTextIntent(this.cause);

  /// {@template flutter.widgets.TextEditingIntents.cause}
  /// The [SelectionChangedCause] that triggered the intent.
  /// {@endtemplate}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to copy or cut
/// the current selection in the field.
class CopySelectionTextIntent extends Intent {
  const CopySelectionTextIntent._(this.cause, this.collapseSelection);

  /// Creates an [Intent] that represents a user interaction that attempts to
  /// cut the current selection in the field.
  const CopySelectionTextIntent.cut(SelectionChangedCause cause) : this._(cause, true);

  /// An [Intent] that represents a user interaction that attempts to copy the
  /// current selection in the field.
  static const CopySelectionTextIntent copy = CopySelectionTextIntent._(SelectionChangedCause.keyboard, false);

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;

  /// Whether the original text needs to be removed from the input field if the
  /// copy action was successful.
  final bool collapseSelection;
}

/// An [Intent] to paste text from [Clipboard] to the field.
class PasteTextIntent extends Intent {
  /// Creates an instance of [PasteTextIntent].
  const PasteTextIntent(this.cause);

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to modify the
/// current [TextEditingValue] in an input field.
class ReplaceTextIntent extends Intent {
  /// Creates a [ReplaceTextIntent].
  const ReplaceTextIntent(this.currentTextEditingValue, this.replacementText, this.replacementRange, this.cause);

  /// The [TextEditingValue] that this [Intent]'s action should perform on.
  final TextEditingValue currentTextEditingValue;

  /// The text to replace the original text within the [replacementRange] with.
  final String replacementText;

  /// The range of text in [currentTextEditingValue] that needs to be replaced.
  final TextRange replacementRange;

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user interaction that attempts to change the
/// selection in an input field.
class UpdateSelectionIntent extends Intent {
  /// Creates a [UpdateSelectionIntent].
  const UpdateSelectionIntent(this.currentTextEditingValue, this.newSelection, this.cause);

  /// The [TextEditingValue] that this [Intent]'s action should perform on.
  final TextEditingValue currentTextEditingValue;

  /// The new [TextSelection] the input field should adopt.
  final TextSelection newSelection;

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents an autofill attempt made by the system's
/// autofill service.
///
/// On platforms where autofill is not distinguishable from regular user input,
/// autofill may be interpreted as a [UpdateTextEditingValueIntent] instead
/// of a [PerformAutofillIntent].
class PerformAutofillIntent extends Intent {
  /// Creates a [PerformAutofillIntent].
  const PerformAutofillIntent(this.autofillValue);

  /// The [TextEditingValue]s to be autofilled.
  ///
  /// The map is keyed by [AutofillClient.autofillId] which is the unique
  /// identifier of an autofill-enabled text input field.
  final Map<String, TextEditingValue> autofillValue;
}

/// An [Intent] that represents a [TextInputAction].
class PerformIMEActionIntent extends Intent {
  /// Creates a [PerformIMEActionIntent].
  const PerformIMEActionIntent(this.textInputAction);

  /// The [TextInputAction] to be performed.
  final TextInputAction textInputAction;
}

/// An [Intent] that represents a user action that replaces the content of an
/// editable text field with a different [TextEditingValue].
///
/// One example of such user actions is autofill, where the existing text in
/// the text field gets erased and replaced with the autofilled value. For
/// granular changes made to the text field, such as text deletion and text
/// insertion, use [UpdateTextEditingValueWtihDeltasIntent] if possible.
///
/// See also:
///
///  * [UpdateTextEditingValueWtihDeltasIntent], which makes partial updates
///    to the content of an editable text field.
class UpdateTextEditingValueIntent extends Intent {
  /// Creates a [UpdateTextEditingValueIntent].
  const UpdateTextEditingValueIntent(this.newValue, {
    this.cause = SelectionChangedCause.keyboard,
  });

  /// The new [TextEditingValue] of the target text field.
  final TextEditingValue newValue;

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents a user action, a sequence of user actions that
/// cause granular changes to be made to the current [TextEditingValue] of an
/// editable text field.
///
/// This [Intent] should typically be used over [UpdateTextEditingValueIntent]
/// if the user action does not completely replaces the contexts of the text
/// field in one go, such as inserting text at the caret location.
///
/// See also:
///  * [UpdateTextEditingValueIntent] which represents a single action that
///    replaces the entire text field with a new [TextEditingValue].
class UpdateTextEditingValueWtihDeltasIntent extends Intent {
  /// Creates an [UpdateTextEditingValueWtihDeltasIntent].
  const UpdateTextEditingValueWtihDeltasIntent(this. deltas, {
    this.cause = SelectionChangedCause.keyboard
  });

  /// The [TextEditingDelta] sequence that represents the user initiated text
  /// changes.
  final Iterable<TextEditingDelta> deltas;

  /// {@macro flutter.widgets.TextEditingIntents.cause}
  final SelectionChangedCause cause;
}

/// An [Intent] that represents the state of the [TextInputConnection] has
/// changed on the platform's text input plugin side.
class TextInputConnectionControlIntent extends Intent {
  const TextInputConnectionControlIntent._(this._controlCode);
  final int _controlCode;

  /// The platform's text input plugin has closed the current
  /// [TextInputConnection].
  ///
  /// The input field that initiated the [TextInputConnection] should properly
  /// close the connection and finalize editing upon receiving this [Intent].
  static const TextInputConnectionControlIntent close = TextInputConnectionControlIntent._(0);

  /// The platform's text input plugin has requested a reconnect for the current
  /// [TextInputConnection].
  ///
  /// The platform's text input plugin sends this command when it loses its
  /// state (for example when it had to restart). The input field should
  /// typically call [TextInput.attachConnection] using the existing
  /// [TextInputConnection] object, then call
  /// [TextInputConnection.setEditingState] to send the current
  /// [TextEditingValue] of the connected text field to the platform.
  static const TextInputConnectionControlIntent reconnect = TextInputConnectionControlIntent._(1);

  @override
  String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    switch (_controlCode) {
      case 0: return 'close connection';
      case 1: return 'reconnect';
    }
    return 'unknown control ($_controlCode)';
  }
}

/// An [Intent] triggered by user actions that initiate, update or end an iOS
/// floating cursor session.
///
/// When the user performs a two-finger pan gesture to pick up the cursor, UIKit
/// initiates a floating cursor session that allows the user to move the cursor
/// freely using the pan gesture.
///
/// This [Intent] will be sent to the text field whenever the state of the
/// floating cursor changes. Text field implementers should provide visual
/// feedback in response to these changes, should they choose to support
/// floating cursor on iOS.
class UpdateFloatingCursorIntent extends Intent {
  /// Creates a [UpdateFloatingCursorIntent].
  const UpdateFloatingCursorIntent(this.floatingCursorPoint);

  /// The state of the current floating cursor session reported by the iOS text
  /// input control.
  final RawFloatingCursorPoint floatingCursorPoint;
}

/// An [Intent] triggers when iOS detects misspelled words or text replacement
/// candidates in recently typed text.
///
/// See also:
///
///  * [iOS text replacement and autocorrect](https://support.apple.com/en-us/HT207525).
class HighlightiOSReplacementRangeIntent extends Intent {
  /// Creates a [HighlightiOSReplacementRangeIntent].
  const HighlightiOSReplacementRangeIntent(this.highlightRange);

  /// The range of the text in the text field needs to be highlighted to
  /// indicate of the range of autocorrect.
  final TextRange highlightRange;
}
