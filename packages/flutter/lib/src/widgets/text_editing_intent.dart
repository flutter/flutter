// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'actions.dart';
import 'editable_text.dart';

/// An [Intent] related to editing text.
///
/// See also:
///
///   * [TextEditingAction], which is intended to be used with
///     TextEditingIntents.
abstract class TextEditingIntent extends Intent {
  // TODO(justinmc): This maybe can't be final, because it can be invoked
  // multiple times. Maybe it shouldn't be set the second time? But couldn't the
  // focused field change?
  /// The [EditableTextState] that is currently focused.
  ///
  /// When used with [TextEditingAction], this is set automatically.
  late final EditableTextState editableTextState;
}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the alt + arrow left key event.
class AltArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the alt + arrow-right key event.
class AltArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the alt + shift + arrow-left key event.
class AltShiftArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the alt + shift + arrow-right key event.
class AltShiftArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the arrow-down key event.
class ArrowDownTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the arrow-left key event.
class ArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the arrow-right key event.
class ArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the arrow-up key event.
class ArrowUpTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for pressing the context menu's copy button.
class ContextMenuCopyTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + a key event.
class ControlATextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + arrow-left key event.
class ControlArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + arrow-right key event.
class ControlArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + c key event.
class ControlCTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + shift + arrow-left key event.
class ControlShiftArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the control + shift + arrow-right key event.
class ControlShiftArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the end key event.
class EndTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the home key event.
class HomeTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + arrow-down key event.
class MetaArrowDownTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + arrow-left key event.
class MetaArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + arrow-right key event.
class MetaArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + arrow-up key event.
class MetaArrowUpTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + c key event.
class MetaCTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + shift + arrow-down key event.
class MetaShiftArrowDownTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + shift + arrow-left key event.
class MetaShiftArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + shift + arrow-right key event.
class MetaShiftArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the meta + shift + arrow-up key event.
class MetaShiftArrowUpTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + arrow-down key event.
class ShiftArrowDownTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + arrow-left key event.
class ShiftArrowLeftTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + arrow-right key event.
class ShiftArrowRightTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + arrow-up key event.
class ShiftArrowUpTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + end key event.
class ShiftEndTextIntent extends TextEditingIntent {}

/// An [Intent] representing the default text editing behavior for the current
/// platform for the shift + home key event.
class ShiftHomeTextIntent extends TextEditingIntent {}
