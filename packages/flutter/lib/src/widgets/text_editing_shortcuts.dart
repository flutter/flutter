// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'actions.dart';
import 'framework.dart';
import 'shortcuts.dart';
import 'text_editing_intents.dart';

/// A [Shortcuts] widget with the shortcuts used for the default text editing
/// behavior.
///
/// This default behavior can be overridden by placing a [Shortcuts] widget
/// lower in the widget tree than this. See [TextEditingActions] for an example
/// of remapping a text editing [Intent] to a custom [Action].
///
/// {@tool snippet}
///
/// This example shows how to use an additional [Shortcuts] widget to override
/// the left arrow key [Intent] and map it to the right arrow key instead.
///
/// ```dart
/// final TextEditingController controller = TextEditingController(
///   text: "Try using the keyboard's arrow keys and notice that left moves right.",
/// );
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: Shortcuts(
///         shortcuts: <LogicalKeySet, Intent>{
///           LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowRightTextIntent(),
///         },
///         child: TextField(
///           controller: controller,
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TextEditingActions], which contains all of the [Action]s that respond
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

  static final Map<LogicalKeySet, Intent> _androidShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    // meta + arrow down is not handled by this platform.

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
  };

  static final Map<LogicalKeySet, Intent> _fuchsiaShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    // meta + arrow down is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _iOSShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    // meta + arrow down is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _linuxShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    // meta + arrow down is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _macShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown):  MoveSelectionToEndTextIntent(),
  };

  static final Map<LogicalKeySet, Intent> _windowsShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    // meta + arrow down is not handled by this platform.
  };

  static Map<LogicalKeySet, Intent> get _shortcuts {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidShortcuts;
      case TargetPlatform.fuchsia:
        return _fuchsiaShortcuts;
      case TargetPlatform.iOS:
        return _iOSShortcuts;
      case TargetPlatform.linux:
        return _linuxShortcuts;
      case TargetPlatform.macOS:
        return _macShortcuts;
      case TargetPlatform.windows:
        return _windowsShortcuts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      debugLabel: '<Default Text Editing Shortcuts>',
      shortcuts: _shortcuts,
      child: child,
    );
  }
}
