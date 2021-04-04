// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'actions.dart';

/// An [Intent] to send the event straight to the engine, but only if a
/// TextEditingTarget is focused.
///
/// {@template flutter.widgets.TextEditingIntents.seeAlso}
/// See also:
///
///   * [DefaultTextEditingActions], which responds to this [Intent].
///   * [DefaultTextEditingShortcuts], which triggers this [Intent].
/// {@endtemplate}
class DoNothingAndStopPropagationTextIntent extends Intent{
  /// Creates an instance of DoNothingAndStopPropagationTextIntent.
  const DoNothingAndStopPropagationTextIntent();
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
class ExpandSelectionRightByLineTextIntent extends Intent{
  /// Creates an instance of ExpandSelectionRightByLineTextIntent.
  const ExpandSelectionRightByLineTextIntent();
}

/// An [Intent] to expand the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToEndTextIntent extends Intent{
  /// Creates an instance of ExpandSelectionToEndTextIntent.
  const ExpandSelectionToEndTextIntent();
}

/// An [Intent] to expand the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToStartTextIntent extends Intent{
  /// Creates an instance of ExpandSelectionToStartTextIntent.
  const ExpandSelectionToStartTextIntent();
}

/// An [Intent] to extend the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionDownTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionDownTextIntent.
  const ExtendSelectionDownTextIntent();
}

/// An [Intent] to extend the selection left to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByLineTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionLeftByLineTextIntent.
  const ExtendSelectionLeftByLineTextIntent();
}

/// An [Intent] to extend the selection left past the nearest word, collapsing
/// the selection if the order of [TextSelection.extentOffset] and
/// [TextSelection.baseOffset] would reverse.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordAndStopAtReversalTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionLeftByWordAndStopAtReversalTextIntent.
  const ExtendSelectionLeftByWordAndStopAtReversalTextIntent();
}

/// An [Intent] to extend the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionLeftByWordTextIntent.
  const ExtendSelectionLeftByWordTextIntent();
}

/// An [Intent] to extend the selection left by one character.
/// platform for the shift + arrow-left key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionLeftTextIntent.
  const ExtendSelectionLeftTextIntent();
}

/// An [Intent] to extend the selection right to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByLineTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionRightByLineTextIntent.
  const ExtendSelectionRightByLineTextIntent();
}

/// An [Intent] to extend the selection right past the nearest word, collapsing
/// the selection if the order of [TextSelection.extentOffset] and
/// [TextSelection.baseOffset] would reverse.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordAndStopAtReversalTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionRightByWordAndStopAtReversalTextIntent.
  const ExtendSelectionRightByWordAndStopAtReversalTextIntent();
}

/// An [Intent] to extend the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionRightByWordTextIntent.
  const ExtendSelectionRightByWordTextIntent();
}

/// An [Intent] to extend the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionRightTextIntent.
  const ExtendSelectionRightTextIntent();
}

/// An [Intent] to extend the selection up by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionUpTextIntent extends Intent{
  /// Creates an instance of ExtendSelectionUpTextIntent.
  const ExtendSelectionUpTextIntent();
}

/// An [Intent] to move the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionDownTextIntent extends Intent{
  /// Creates an instance of MoveSelectionDownTextIntent.
  const MoveSelectionDownTextIntent();
}

/// An [Intent] to move the selection left by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByLineTextIntent extends Intent{
  /// Creates an instance of MoveSelectionLeftByLineTextIntent.
  const MoveSelectionLeftByLineTextIntent();
}

/// An [Intent] to move the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByWordTextIntent extends Intent{
  /// Creates an instance of MoveSelectionLeftByWordTextIntent.
  const MoveSelectionLeftByWordTextIntent();
}

/// An [Intent] to move the selection left by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftTextIntent extends Intent{
  /// Creates an instance of MoveSelectionLeftTextIntent.
  const MoveSelectionLeftTextIntent();
}

/// An [Intent] to move the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToStartTextIntent extends Intent{
  /// Creates an instance of MoveSelectionToStartTextIntent.
  const MoveSelectionToStartTextIntent();
}

/// An [Intent] to move the selection right by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByLineTextIntent extends Intent{
  /// Creates an instance of MoveSelectionRightByLineTextIntent.
  const MoveSelectionRightByLineTextIntent();
}

/// An [Intent] to move the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByWordTextIntent extends Intent{
  /// Creates an instance of MoveSelectionRightByWordTextIntent.
  const MoveSelectionRightByWordTextIntent();
}

/// An [Intent] to move the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightTextIntent extends Intent{
  /// Creates an instance of MoveSelectionRightTextIntent.
  const MoveSelectionRightTextIntent();
}

/// An [Intent] to move the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToEndTextIntent extends Intent{
  /// Creates an instance of MoveSelectionToEndTextIntent.
  const MoveSelectionToEndTextIntent();
}

/// An [Intent] to move the selection up by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionUpTextIntent extends Intent{
  /// Creates an instance of MoveSelectionUpTextIntent.
  const MoveSelectionUpTextIntent();
}
