// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'actions.dart';

/// An [Intent] to expand the selection left to the start/end of the current
/// line.
///
/// {@template flutter.widgets.TextEditingIntents.seeAlso}
/// See also:
///
///   * [DefaultTextEditingActions], which responds to this [Intent].
///   * [DefaultTextEditingShortcuts], which triggers this [Intent].
/// {@endtemplate}
class ExpandSelectionLeftByLineTextIntent extends Intent {}

/// An [Intent] to expand the selection right to the start/end of the current
/// field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionRightByLineTextIntent extends Intent {}

/// An [Intent] to expand the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToEndTextIntent extends Intent {}

/// An [Intent] to expand the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToStartTextIntent extends Intent {}

/// An [Intent] to extend the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionDownTextIntent extends Intent {}

/// An [Intent] to extend the selection left to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByLineTextIntent extends Intent {}

/// An [Intent] to extend the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordTextIntent extends Intent {}

/// An [Intent] to extend the selection left by one character.
/// platform for the shift + arrow-left key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftTextIntent extends Intent {}

/// An [Intent] to extend the selection right to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByLineTextIntent extends Intent {}

/// An [Intent] to extend the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordTextIntent extends Intent {}

/// An [Intent] to extend the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightTextIntent extends Intent {}

/// An [Intent] to extend the selection up by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionUpTextIntent extends Intent {}

/// An [Intent] to move the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionDownTextIntent extends Intent {}

/// An [Intent] to move the selection left by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByLineTextIntent extends Intent {}

/// An [Intent] to move the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByWordTextIntent extends Intent {}

/// An [Intent] to move the selection left by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftTextIntent extends Intent {}

/// An [Intent] to move the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToStartTextIntent extends Intent {}

/// An [Intent] to move the selection right by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByLineTextIntent extends Intent {}

/// An [Intent] to move the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByWordTextIntent extends Intent {}

/// An [Intent] to move the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightTextIntent extends Intent {}

/// An [Intent] to move the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToEndTextIntent extends Intent {}

/// An [Intent] to move the selection up by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionUpTextIntent extends Intent {}
