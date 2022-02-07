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
