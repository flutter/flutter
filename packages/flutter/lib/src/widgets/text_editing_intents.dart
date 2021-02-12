// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'actions.dart';

/// An [Intent] to expand the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToEndTextIntent extends Intent {}

/// An [Intent] to move the selection left by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByLineTextIntent extends Intent {}

/// An [Intent] to move the selection right by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByLineTextIntent extends Intent {}

/// An [Intent] to move the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToStartTextIntent extends Intent {}

/// An [Intent] to expand the selection left to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionLeftByLineTextIntent extends Intent {}

/// An [Intent] to expand the selection right to the start/end of the current
/// field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionRightByLineTextIntent extends Intent {}

/// An [Intent] to expand the selection to the start of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExpandSelectionToStartTextIntent extends Intent {}

// TODO(justinmc): Put this template in the first Intent here alphabetically.
/// An [Intent] to move the selection down by one line.
///
/// {@template flutter.widgets.TextEditingIntents.seeAlso}
/// See also:
///
///   * [TextEditingActions], which responds to this [Intent].
///   * [TextEditingShortcuts], which triggers this [Intent].
/// {@endtemplate}
class MoveSelectionDownTextIntent extends Intent {}

/// An [Intent] to move the selection left by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftTextIntent extends Intent {}

/// An [Intent] to move the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightTextIntent extends Intent {}

/// An [Intent] to move the selection up by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionUpTextIntent extends Intent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for pressing the context menu's copy button.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ContextMenuCopyTextIntent extends Intent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + a key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ControlATextIntent extends Intent {}

/// An [Intent] to move the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionLeftByWordTextIntent extends Intent {}

/// An [Intent] to move the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionRightByWordTextIntent extends Intent {}

/// An [Intent] to extend the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordTextIntent extends Intent {}

/// An [Intent] to extend the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordTextIntent extends Intent {}

/// An [Intent] to move the selection to the end of the field.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MoveSelectionToEndTextIntent extends Intent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + c key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MetaCTextIntent extends Intent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + shift + arrow-left key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class MetaShiftArrowLeftTextIntent extends Intent {}

/// An [Intent] to extend the selection down by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionDownTextIntent extends Intent {}

/// An [Intent] to extend the selection left by one character.
/// platform for the shift + arrow-left key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftTextIntent extends Intent {}

/// An [Intent] to extend the selection right by one character.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightTextIntent extends Intent {}

/// An [Intent] to extend the selection up by one line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionUpTextIntent extends Intent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + end key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ShiftEndTextIntent extends Intent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + home key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ShiftHomeTextIntent extends Intent {}
