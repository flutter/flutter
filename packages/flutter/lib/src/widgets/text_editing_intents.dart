// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'actions.dart';
import 'editable_text.dart';
import 'text_selection.dart';
import 'text_selection_gestures.dart';

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

/// An [Intent] to send the event straight to the engine, but only if a
/// TextEditingTarget is focused.
///
/// {@template flutter.widgets.TextEditingIntents.seeAlso}
/// See also:
///
///   * [DefaultTextEditingActions], which responds to this [Intent].
///   * [DefaultTextEditingShortcuts], which triggers this [Intent].
/// {@endtemplate}
class DoNothingAndStopPropagationTextIntent extends Intent {
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

/// An [Intent] to extend the selection left to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByLineTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionLeftByLineTextIntent.
  const ExtendSelectionLeftByLineTextIntent();
}

/// An [Intent] to extend the selection left past the nearest word, collapsing
/// the selection if the order of [TextSelection.extentOffset] and
/// [TextSelection.baseOffset] would reverse.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordAndStopAtReversalTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionLeftByWordAndStopAtReversalTextIntent.
  const ExtendSelectionLeftByWordAndStopAtReversalTextIntent();
}

/// An [Intent] to extend the selection left past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftByWordTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionLeftByWordTextIntent.
  const ExtendSelectionLeftByWordTextIntent();
}

/// An [Intent] to extend the selection left by one character.
/// platform for the shift + arrow-left key event.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionLeftTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionLeftTextIntent.
  const ExtendSelectionLeftTextIntent();
}

/// An [Intent] to extend the selection right to the start/end of the current
/// line.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByLineTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionRightByLineTextIntent.
  const ExtendSelectionRightByLineTextIntent();
}

/// An [Intent] to extend the selection right past the nearest word, collapsing
/// the selection if the order of [TextSelection.extentOffset] and
/// [TextSelection.baseOffset] would reverse.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordAndStopAtReversalTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionRightByWordAndStopAtReversalTextIntent.
  const ExtendSelectionRightByWordAndStopAtReversalTextIntent();
}

/// An [Intent] to extend the selection right past the nearest word.
///
/// {@macro flutter.widgets.TextEditingIntents.seeAlso}
class ExtendSelectionRightByWordTextIntent extends Intent {
  /// Creates an instance of ExtendSelectionRightByWordTextIntent.
  const ExtendSelectionRightByWordTextIntent();
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

// ---------- Gesture Intents ----------

/// An [Intent] that represents a gesture, or a potential gesture that has yet
/// to be recognized.
abstract class TextEditingGestureIntent extends Intent {
  /// Creates an [Intent] that represents a gesture, or a potential gesture that
  /// has yet to be recognized, that happened in a text field associated with
  /// [gestureDelegate].
  const TextEditingGestureIntent({
    required this.gestureDelegate,
  });

  /// The [TextSelectionGestureDetectorBuilderDelegate] that received the
  /// gesture event, which may be part of the gesture this [Intent] represents.
  final TextSelectionGestureDetectorBuilderDelegate gestureDelegate;
}

abstract class _TextEditingGestureIntent<GestureStatus> extends TextEditingGestureIntent {
  const _TextEditingGestureIntent({
    required TextSelectionGestureDetectorBuilderDelegate gestureDelegate,
    required this.gestureStatus,
  }) : super(gestureDelegate: gestureDelegate);

  /// The current status of the gesture recognition process.
  final GestureStatus gestureStatus;
}

class ForcePressTextGestureIntent extends _TextEditingGestureIntent<ForcePressTextGestureStatus> {
  const ForcePressTextGestureIntent({
    required ForcePressTextGestureStatus gestureStatus,
    required TextSelectionGestureDetectorBuilderDelegate gestureDelegate,
  }) : super(gestureDelegate: gestureDelegate, gestureStatus: gestureStatus);
}

class TapTextGestureIntent extends _TextEditingGestureIntent<TapTextGestureStatus> {
  const TapTextGestureIntent({
    required  TapTextGestureStatus gestureStatus,
    required this.maxTapCount,
    required TextSelectionGestureDetectorBuilderDelegate gestureDelegate,
  }) : assert(maxTapCount > 0),
       super(gestureDelegate: gestureDelegate, gestureStatus: gestureStatus);

  final int maxTapCount;

  bool get shouldShowSelectionBar {
    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus). A mouse shouldn't
    // trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    switch (gestureStatus.tapDownDetails.kind) {
      case null:
      case PointerDeviceKind.touch:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.unknown:
        return false;
    }
  }
}

class SecondaryTapTextGestureIntent extends _TextEditingGestureIntent<SecondaryTapTextGestureStatus > {
  const SecondaryTapTextGestureIntent({
    required SecondaryTapTextGestureStatus gestureStatus,
    required TextSelectionGestureDetectorBuilderDelegate gestureDelegate,
  }) : super(gestureDelegate: gestureDelegate, gestureStatus: gestureStatus);
}

class LongPressTextGestureIntent extends _TextEditingGestureIntent<LongPressTextGestureStatus> {
  const LongPressTextGestureIntent({
    required LongPressTextGestureStatus gestureStatus,
    required TextSelectionGestureDetectorBuilderDelegate gestureDelegate,
  }) : super(gestureDelegate: gestureDelegate, gestureStatus: gestureStatus);
}

class DragTextGestureIntent extends _TextEditingGestureIntent<DragTextGestureStatus> {
  DragTextGestureIntent({
    required DragTextGestureStatus gestureStatus,
    required TextSelectionGestureDetectorBuilderDelegate gestureDelegate,
  }) : super(gestureDelegate: gestureDelegate, gestureStatus: gestureStatus);

  TextPosition? selectionBase;

  bool get shouldShowSelectionBar {
    switch (gestureStatus.dragStartDetails.kind) {
      case null:
      case PointerDeviceKind.touch:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.unknown:
        return false;
    }
  }
}

