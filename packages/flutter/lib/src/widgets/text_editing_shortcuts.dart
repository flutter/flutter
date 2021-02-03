// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import 'actions.dart';
import 'framework.dart';
import 'shortcuts.dart';
import 'text_editing_intents.dart';

/// A [Shortcuts] widget with the shortcuts used for the default text editing
/// behavior.
///
/// See also:
///
///  * [TextEditingActions], which contains all of the [Action]s that respond
///    to the [Intent]s in these shortcuts with the default text editing
///    behavior.
class TextEditingShortcuts extends StatelessWidget {
  /// Creates an instance of TextEditingShortcuts.
  TextEditingShortcuts({
    Map<LogicalKeySet, Intent>? additionalShortcuts,
    this.debugLabel,
    Key? key,
    required this.child,
  }) : additionalShortcuts = additionalShortcuts ?? <LogicalKeySet, Intent>{},
       super(key: key);

  /// The actions to be merged with the default text editing actions.
  ///
  /// The default text editing actions will override any conflicting keys in
  /// additionalActions. To override the default text editing actions, use an
  /// [Actions] Widget in the tree below this Widget.
  final Map<LogicalKeySet, Intent> additionalShortcuts;

  /// The child [Widget].
  final Widget child;

  /// Passed through to [Shortcuts.debugLabel].
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      debugLabel: debugLabel,
      shortcuts: <LogicalKeySet, Intent>{
        ...additionalShortcuts,
        LogicalKeySet(LogicalKeyboardKey.arrowDown): ArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): ArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): AltArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): AltArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): AltArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): AltArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): AltShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): AltShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): AltShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): AltShiftArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  ControlArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  ControlArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ControlShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ControlShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.end):  EndTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.home):  HomeTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):  MetaCTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown):  MetaArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight):  MetaArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft):  MetaArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp):  MetaArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown):  MetaShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  MetaShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  MetaShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp):  MetaShiftArrowUpTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ShiftArrowDownTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ShiftArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.home):  ShiftHomeTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.end):  ShiftEndTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ShiftArrowUpTextIntent(),
      },
      child: child,
    );
  }
}
