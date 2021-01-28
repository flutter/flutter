// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'text_editing_actions.dart';

/// A [Shortcuts] widget with the shortcuts used for the default text editing
/// behavior.
///
/// See also:
///
///  * [textEditingActionsMap], which contains all of the actions that respond
///    to the [Intent]s in these shortcuts with the default text editing
///    behavior.
class TextEditingShortcuts extends StatelessWidget {
  /// Creates an instance of TextEditingShortcuts.
  const TextEditingShortcuts({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child [Widget].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const ArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const ArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const AltArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const AltArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const AltShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const AltShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): const ControlArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): const ControlArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ControlShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ControlShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): ControlATextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC): ControlCTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.end): const EndTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.home): const HomeTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC): const MetaCTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown): const MetaArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight): const MetaArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft): const MetaArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp): const MetaArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const MetaShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const MetaShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const MetaShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const MetaShiftArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.home): const ShiftHomeTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.end): const ShiftEndTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ShiftArrowUpTextIntent(),
      },
      child: child,
    );
  }
}
