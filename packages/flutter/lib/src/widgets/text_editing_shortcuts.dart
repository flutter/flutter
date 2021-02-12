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
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.end):  MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.home):  MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionUpTextIntent(),
    // End is not handled by this platform.
    // Home is not handled by this platform.
    // Meta + arrow down is not handled by this platform.
    // Meta + arrow left is not handled by this platform.
    // Meta + arrow right is not handled by this platform.
    // Meta + arrow up is not handled by this platform.
    // Meta + shift + arrow down is not handled by this platform.
    // Meta + shift + arrow left is not handled by this platform.
    // Meta + shift + arrow right is not handled by this platform.
    // Meta + shift + arrow up is not handled by this platform.
    // Shift + end is not handled by this platform.
    // Shift + home is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _fuchsiaShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionUpTextIntent(),
    // Meta + arrow down is not handled by this platform.
    // End is not handled by this platform.
    // Home is not handled by this platform.
    // Meta + arrow left is not handled by this platform.
    // Meta + arrow right is not handled by this platform.
    // Meta + arrow up is not handled by this platform.
    // Meta + shift + arrow down is not handled by this platform.
    // Meta + shift + arrow left is not handled by this platform.
    // Meta + shift + arrow right is not handled by this platform.
    // Meta + shift + arrow up is not handled by this platform.
    // Shift + end is not handled by this platform.
    // Shift + home is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _iOSShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionUpTextIntent(),
    // Meta + arrow down is not handled by this platform.
    // End is not handled by this platform.
    // Home is not handled by this platform.
    // Meta + arrow left is not handled by this platform.
    // Meta + arrow right is not handled by this platform.
    // Meta + arrow up is not handled by this platform.
    // Meta + shift + arrow down is not handled by this platform.
    // Meta + shift + arrow left is not handled by this platform.
    // Meta + shift + arrow right is not handled by this platform.
    // Meta + shift + arrow up is not handled by this platform.
    // Shift + end is not handled by this platform.
    // Shift + home is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _linuxShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionUpTextIntent(),
    // Meta + arrow down is not handled by this platform.
    // End is not handled by this platform.
    // Home is not handled by this platform.
    // Meta + arrow left is not handled by this platform.
    // Meta + arrow right is not handled by this platform.
    // Meta + arrow up is not handled by this platform.
    // Meta + shift + arrow down is not handled by this platform.
    // Meta + shift + arrow left is not handled by this platform.
    // Meta + shift + arrow right is not handled by this platform.
    // Meta + shift + arrow up is not handled by this platform.
    // Shift + end is not handled by this platform.
    // Shift + home is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _macShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown):  MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft):  MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight):  MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp):  MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown):  ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp):  ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionUpTextIntent(),
    // Control + arrow left is not handled by this platform.
    // Control + arrow right is not handled by this platform.
    // Control + shift + arrow left is not handled by this platform.
    // Control + shift + arrow right is not handled by this platform.
    // End is not handled by this platform.
    // Home is not handled by this platform.
    // Shift + end is not handled by this platform.
    // Shift + home is not handled by this platform.
  };

  static final Map<LogicalKeySet, Intent> _windowsShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft):  MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight):  MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):  ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):  ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): ExtendSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.end):  ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.home):  ExpandSelectionLeftByLineTextIntent(),
    // Meta + arrow down is not handled by this platform.
    // Meta + arrow left is not handled by this platform.
    // Meta + arrow right is not handled by this platform.
    // Meta + arrow up is not handled by this platform.
    // Meta + shift + arrow down is not handled by this platform.
    // Meta + shift + arrow left is not handled by this platform.
    // Meta + shift + arrow right is not handled by this platform.
    // Meta + shift + arrow up is not handled by this platform.
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
