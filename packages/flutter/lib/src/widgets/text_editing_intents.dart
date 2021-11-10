// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import 'actions.dart';

/// An [Intent] to send the event straight to the engine.
///
/// See also:
///
///   * [DefaultTextEditingShortcuts], which triggers this [Intent].
class DoNothingAndStopPropagationTextIntent extends Intent {
  /// Creates an instance of [DoNothingAndStopPropagationTextIntent].
  const DoNothingAndStopPropagationTextIntent();
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
  const DirectionalCaretMovementIntent(bool forward, this.collapseSelection)
    : super(forward);

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
  }) : super(forward, collapseSelection);
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

// These Intents are deprecated.

/// An [Intent] to delete a character in the backwards direction.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class DeleteTextIntent extends Intent {
  /// Creates an instance of DeleteTextIntent.
  const DeleteTextIntent();
}

/// An [Intent] to delete a word in the backwards direction.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class DeleteByWordTextIntent extends Intent {
  /// Creates an instance of DeleteByWordTextIntent.
  const DeleteByWordTextIntent();
}

/// An [Intent] to delete a line in the backwards direction.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class DeleteByLineTextIntent extends Intent {
  /// Creates an instance of DeleteByLineTextIntent.
  const DeleteByLineTextIntent();
}

/// An [Intent] to delete in the forward direction.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class DeleteForwardTextIntent extends Intent {
  /// Creates an instance of DeleteForwardTextIntent.
  const DeleteForwardTextIntent();
}

/// An [Intent] to delete a word in the forward direction.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class DeleteForwardByWordTextIntent extends Intent {
  /// Creates an instance of DeleteByWordTextIntent.
  const DeleteForwardByWordTextIntent();
}

/// An [Intent] to delete a line in the forward direction.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class DeleteForwardByLineTextIntent extends Intent {
  /// Creates an instance of DeleteByLineTextIntent.
  const DeleteForwardByLineTextIntent();
}

/// An [Intent] to expand the selection left to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionLeftByLineTextIntent extends Intent {
  /// Creates an instance of ExpandSelectionLeftByLineTextIntent.
  const ExpandSelectionLeftByLineTextIntent();
}

/// An [Intent] to expand the selection right to the start/end of the current
/// field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionRightByLineTextIntent extends Intent {
  /// Creates an instance of ExpandSelectionRightByLineTextIntent.
  const ExpandSelectionRightByLineTextIntent();
}

/// An [Intent] to expand the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToEndTextIntent extends Intent {
  /// Creates an instance of ExpandSelectionToEndTextIntent.
  const ExpandSelectionToEndTextIntent();
}

/// An [Intent] to expand the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToStartTextIntent extends Intent {
  /// Creates an instance of ExpandSelectionToStartTextIntent.
  const ExpandSelectionToStartTextIntent();
}

/// An [Intent] to extend the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionDownTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionDownTextIntent.
  const ExtendSelectionDownTextIntent();
}

/// An [Intent] to extend the selection left by one character.
/// platform for the shift + arrow-left key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionLeftTextIntent.
  const ExtendSelectionLeftTextIntent();
}

/// An [Intent] to extend the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionRightTextIntent.
  const ExtendSelectionRightTextIntent();
}

/// An [Intent] to extend the selection up by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionUpTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionUpTextIntent.
  const ExtendSelectionUpTextIntent();
}

/// An [Intent] to extend the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionLeftByWordTextIntent.
  const ExtendSelectionLeftByWordTextIntent();
}

/// An [Intent] to extend the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionRightByWordTextIntent.
  const ExtendSelectionRightByWordTextIntent();
}

/// An [Intent] to move the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionDownTextIntent extends Intent {
  /// Creates an instance of MoveSelectionDownTextIntent.
  const MoveSelectionDownTextIntent();
}

/// An [Intent] to move the selection left by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByLineTextIntent extends Intent {
  /// Creates an instance of MoveSelectionLeftByLineTextIntent.
  const MoveSelectionLeftByLineTextIntent();
}

/// An [Intent] to move the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByWordTextIntent extends Intent {
  /// Creates an instance of MoveSelectionLeftByWordTextIntent.
  const MoveSelectionLeftByWordTextIntent();
}

/// An [Intent] to move the selection left by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftTextIntent extends Intent {
  /// Creates an instance of MoveSelectionLeftTextIntent.
  const MoveSelectionLeftTextIntent();
}

/// An [Intent] to move the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToStartTextIntent extends Intent {
  /// Creates an instance of MoveSelectionToStartTextIntent.
  const MoveSelectionToStartTextIntent();
}

/// An [Intent] to move the selection right by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByLineTextIntent extends Intent {
  /// Creates an instance of MoveSelectionRightByLineTextIntent.
  const MoveSelectionRightByLineTextIntent();
}

/// An [Intent] to move the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByWordTextIntent extends Intent {
  /// Creates an instance of MoveSelectionRightByWordTextIntent.
  const MoveSelectionRightByWordTextIntent();
}

/// An [Intent] to move the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightTextIntent extends Intent {
  /// Creates an instance of MoveSelectionRightTextIntent.
  const MoveSelectionRightTextIntent();
}

/// An [Intent] to move the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToEndTextIntent extends Intent {
  /// Creates an instance of MoveSelectionToEndTextIntent.
  const MoveSelectionToEndTextIntent();
}

/// An [Intent] to move the selection up by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionUpTextIntent extends Intent {
  /// Creates an instance of MoveSelectionUpTextIntent.
  const MoveSelectionUpTextIntent();
}
