// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'framework.dart';
import 'shortcuts.dart';
import 'text_editing_intents.dart';

/// A [Shortcuts] widget with the shortcuts used for the default text editing
/// behavior.
///
/// This default behavior can be overridden by placing a [Shortcuts] widget
/// lower in the widget tree than this. See the [Action] class for an example
/// of remapping an [Intent] to a custom [Action].
///
/// {@tool snippet}
///
/// This example shows how to use an additional [Shortcuts] widget to override
/// some default text editing keyboard shortcuts to have new behavior. Instead
/// of moving the cursor, alt + up/down will change the focused widget.
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   // If using WidgetsApp or its descendents MaterialApp or CupertinoApp,
///   // then DefaultTextEditingShortcuts is already being inserted into the
///   // widget tree.
///   return DefaultTextEditingShortcuts(
///     child: Center(
///       child: Shortcuts(
///         shortcuts: const <ShortcutActivator, Intent>{
///           SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): NextFocusIntent(),
///           SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): PreviousFocusIntent(),
///         },
///         child: Column(
///           children: const <Widget>[
///             TextField(
///               decoration: InputDecoration(
///                 hintText: 'alt + down moves to the next field.',
///               ),
///             ),
///             TextField(
///               decoration: InputDecoration(
///                 hintText: 'And alt + up moves to the previous.',
///               ),
///             ),
///           ],
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// This example shows how to use an additional [Shortcuts] widget to override
/// default text editing shortcuts to have completely custom behavior defined by
/// a custom Intent and Action. Here, the up/down arrow keys increment/decrement
/// a counter instead of moving the cursor.
///
/// ```dart
/// class IncrementCounterIntent extends Intent {}
/// class DecrementCounterIntent extends Intent {}
///
/// class MyWidget extends StatefulWidget {
///   const MyWidget({ Key? key }) : super(key: key);
///
///   @override
///   MyWidgetState createState() => MyWidgetState();
/// }
///
/// class MyWidgetState extends State<MyWidget> {
///
///   int _counter = 0;
///
///   @override
///   Widget build(BuildContext context) {
///     // If using WidgetsApp or its descendents MaterialApp or CupertinoApp,
///     // then DefaultTextEditingShortcuts is already being inserted into the
///     // widget tree.
///     return DefaultTextEditingShortcuts(
///       child: Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: <Widget>[
///             const Text(
///               'You have pushed the button this many times:',
///             ),
///             Text(
///               '$_counter',
///               style: Theme.of(context).textTheme.headline4,
///             ),
///             Shortcuts(
///               shortcuts: <ShortcutActivator, Intent>{
///                 const SingleActivator(LogicalKeyboardKey.arrowUp): IncrementCounterIntent(),
///                 const SingleActivator(LogicalKeyboardKey.arrowDown): DecrementCounterIntent(),
///               },
///               child: Actions(
///                 actions: <Type, Action<Intent>>{
///                   IncrementCounterIntent: CallbackAction<IncrementCounterIntent>(
///                     onInvoke: (IncrementCounterIntent intent) {
///                       setState(() {
///                         _counter++;
///                       });
///                     },
///                   ),
///                   DecrementCounterIntent: CallbackAction<DecrementCounterIntent>(
///                     onInvoke: (DecrementCounterIntent intent) {
///                       setState(() {
///                         _counter--;
///                       });
///                     },
///                   ),
///                 },
///                 child: const TextField(
///                   maxLines: 2,
///                   decoration: InputDecoration(
///                     hintText: 'Up/down increment/decrement here.',
///                   ),
///                 ),
///               ),
///             ),
///             const TextField(
///               maxLines: 2,
///               decoration: InputDecoration(
///                 hintText: 'Up/down behave normally here.',
///               ),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///   * [WidgetsApp], which creates a DefaultTextEditingShortcuts.
class DefaultTextEditingShortcuts extends Shortcuts {
  /// Creates a [Shortcuts] widget that provides the default text editing
  /// shortcuts on the current platform.
  DefaultTextEditingShortcuts({
    Key? key,
    required Widget child,
  }) : super(
    key: key,
    debugLabel: '<Default Text Editing Shortcuts>',
    shortcuts: _shortcuts,
    child: child,
  );

  // These are shortcuts are shared between most platforms except macOS for it
  // uses different modifier keys as the line/word modifer.
  static const Map<ShortcutActivator, Intent> _commonShortcuts = <ShortcutActivator, Intent>{
    // Delete Shortcuts.
    SingleActivator(LogicalKeyboardKey.backspace): DeleteCharacterIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DeleteToNextWordBoundaryIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteToLineBreakIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.delete): DeleteCharacterIntent(forward: true),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DeleteToNextWordBoundaryIntent(forward: true),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteToLineBreakIntent(forward: true),

    // Arrow: Move Selection.
    SingleActivator(LogicalKeyboardKey.arrowLeft): ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowRight): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowUp): ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowDown): ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true),

    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true),

    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.keyX, control: true): CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent.copy,
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(SelectionChangedCause.keyboard),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllTextIntent(SelectionChangedCause.keyboard),
  };

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * End
  //   * Home
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + arrow down
  //   * Meta + arrow left
  //   * Meta + arrow right
  //   * Meta + arrow up
  //   * Meta + shift + arrow down
  //   * Meta + shift + arrow left
  //   * Meta + shift + arrow right
  //   * Meta + shift + arrow up
  //   * Shift + end
  //   * Shift + home
  //   * Meta + delete
  //   * Meta + backspace
  static const Map<ShortcutActivator, Intent> _androidShortcuts = _commonShortcuts;

  // Fuchsia keyboard HID usage values are defined in (page 53):
  // https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf
  static const int _kFuchsiaKeyIdPlane = LogicalKeyboardKey.fuchsiaPlane;

  static const LogicalKeyboardKey _kBackspace = LogicalKeyboardKey(42 | _kFuchsiaKeyIdPlane);
  static const LogicalKeyboardKey _kDelete = LogicalKeyboardKey(76 | _kFuchsiaKeyIdPlane);
  static const LogicalKeyboardKey _kArrowLeft = LogicalKeyboardKey(80 | _kFuchsiaKeyIdPlane);
  static const LogicalKeyboardKey _kArrowRight = LogicalKeyboardKey(79 | _kFuchsiaKeyIdPlane);
  static const LogicalKeyboardKey _kArrowDown = LogicalKeyboardKey(81 | _kFuchsiaKeyIdPlane);
  static const LogicalKeyboardKey _kArrowUp = LogicalKeyboardKey(82 | _kFuchsiaKeyIdPlane);

  static const Map<ShortcutActivator, Intent> _fuchsiaShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(_kBackspace): DeleteCharacterIntent(forward: false),
    SingleActivator(_kBackspace, control: true): DeleteToNextWordBoundaryIntent(forward: false),
    SingleActivator(_kBackspace, alt: true): DeleteToLineBreakIntent(forward: false),
    SingleActivator(_kDelete): DeleteCharacterIntent(forward: true),
    SingleActivator(_kDelete, control: true): DeleteToNextWordBoundaryIntent(forward: true),
    SingleActivator(_kDelete, alt: true): DeleteToLineBreakIntent(forward: true),
    SingleActivator(_kArrowDown, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true),
    SingleActivator(_kArrowLeft, alt: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    SingleActivator(_kArrowRight, alt: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    SingleActivator(_kArrowUp, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true),
    SingleActivator(_kArrowDown, shift: true, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),
    SingleActivator(_kArrowLeft, shift: true, alt: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    SingleActivator(_kArrowRight, shift: true, alt: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    SingleActivator(_kArrowUp, shift: true, alt: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    SingleActivator(_kArrowDown): ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),
    SingleActivator(_kArrowLeft): ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true),
    SingleActivator(_kArrowRight): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    SingleActivator(_kArrowUp): ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    SingleActivator(_kArrowLeft, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true),
    SingleActivator(_kArrowRight, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true),
    SingleActivator(_kArrowLeft, shift: true, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: false),
    SingleActivator(_kArrowRight, shift: true, control: true): ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: false),
    SingleActivator(_kArrowDown, shift: true): ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),
    SingleActivator(_kArrowLeft, shift: true): ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false),
    SingleActivator(_kArrowRight, shift: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false),
    SingleActivator(_kArrowUp, shift: true): ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
  };

  static const Map<ShortcutActivator, Intent> defaultEditingShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(kBackspace): DeleteTextIntent(),
    SingleActivator(kBackspace, control: true): DeleteByWordTextIntent(),
    SingleActivator(kBackspace, alt: true): DeleteByLineTextIntent(),
    SingleActivator(kDelete): DeleteForwardTextIntent(),
    SingleActivator(kDelete, control: true): DeleteForwardByWordTextIntent(),
    SingleActivator(kDelete, alt: true): DeleteForwardByLineTextIntent(),
    SingleActivator(kArrowDown, alt: true): MoveSelectionToEndTextIntent(),
    SingleActivator(kArrowLeft, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(kArrowRight, alt: true):
        MoveSelectionRightByLineTextIntent(),
    SingleActivator(kArrowUp, alt: true): MoveSelectionToStartTextIntent(),
    SingleActivator(kArrowDown, shift: true, alt: true):
        ExpandSelectionToEndTextIntent(),
    SingleActivator(kArrowLeft, shift: true, alt: true):
        ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(kArrowRight, shift: true, alt: true):
        ExpandSelectionRightByLineTextIntent(),
    SingleActivator(kArrowUp, shift: true, alt: true):
        ExpandSelectionToStartTextIntent(),
    SingleActivator(kArrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(kArrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(kArrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(kArrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(kArrowLeft, control: true):
        MoveSelectionLeftByWordTextIntent(),
    SingleActivator(kArrowRight, control: true):
        MoveSelectionRightByWordTextIntent(),
    SingleActivator(kArrowLeft, shift: true, control: true):
        ExtendSelectionLeftByWordTextIntent(),
    SingleActivator(kArrowRight, shift: true, control: true):
        ExtendSelectionRightByWordTextIntent(),
    SingleActivator(kArrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(kArrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(kArrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(kArrowUp, shift: true): ExtendSelectionUpTextIntent(),
  };

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * End
  //   * Home
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + arrow down
  //   * Meta + arrow left
  //   * Meta + arrow right
  //   * Meta + arrow up
  //   * Meta + shift + arrow down
  //   * Meta + shift + arrow left
  //   * Meta + shift + arrow right
  //   * Meta + shift + arrow up
  //   * Shift + end
  //   * Shift + home
  //   * Meta + delete
  //   * Meta + backspace
  static const Map<ShortcutActivator, Intent> _iOSShortcuts = _commonShortcuts;

  static const Map<ShortcutActivator, Intent> _linuxShortcuts = <ShortcutActivator, Intent>{
    ..._commonShortcuts,
    SingleActivator(LogicalKeyboardKey.home): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.end): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.home, shift: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.end, shift: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    // The following key combinations have no effect on text editing on this
    // platform:
    //   * Meta + X
    //   * Meta + C
    //   * Meta + V
    //   * Meta + A
    //   * Meta + arrow down
    //   * Meta + arrow left
    //   * Meta + arrow right
    //   * Meta + arrow up
    //   * Meta + shift + arrow down
    //   * Meta + shift + arrow left
    //   * Meta + shift + arrow right
    //   * Meta + shift + arrow up
    //   * Meta + delete
    //   * Meta + backspace
  };

  // macOS document shortcuts: https://support.apple.com/en-us/HT201236.
  // The macOS shortcuts uses different word/line modifiers than most other
  // platforms.
  static const Map<ShortcutActivator, Intent> _macShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteCharacterIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteToNextWordBoundaryIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.backspace, meta: true): DeleteToLineBreakIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.delete): DeleteCharacterIntent(forward: true),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteToNextWordBoundaryIntent(forward: true),
    SingleActivator(LogicalKeyboardKey.delete, meta: true): DeleteToLineBreakIntent(forward: true),

    SingleActivator(LogicalKeyboardKey.arrowLeft): ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowRight): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowUp): ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowDown): ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),

    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(forward: false),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(forward: true),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true),
    SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true),

    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, meta: true): ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, meta: true): ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, meta: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.home, shift: true): ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    SingleActivator(LogicalKeyboardKey.end, shift: true): ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),

    SingleActivator(LogicalKeyboardKey.keyX, meta: true): CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
    SingleActivator(LogicalKeyboardKey.keyC, meta: true): CopySelectionTextIntent.copy,
    SingleActivator(LogicalKeyboardKey.keyV, meta: true): PasteTextIntent(SelectionChangedCause.keyboard),
    SingleActivator(LogicalKeyboardKey.keyA, meta: true): SelectAllTextIntent(SelectionChangedCause.keyboard),
  };

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + arrow down
  //   * Meta + arrow left
  //   * Meta + arrow right
  //   * Meta + arrow up
  //   * Meta + shift + arrow down
  //   * Meta + shift + arrow left
  //   * Meta + shift + arrow right
  //   * Meta + shift + arrow up
  //   * Meta + delete
  //   * Meta + backspace
  static const Map<ShortcutActivator, Intent> _windowsShortcuts = _linuxShortcuts;

  // Web handles its text selection natively and doesn't use any of these
  // shortcuts in Flutter.
  static const Map<ShortcutActivator, Intent> _webShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.end): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.home): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.end, shift: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.home, shift: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.space): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, meta: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): DoNothingAndStopPropagationTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, meta: true): DoNothingAndStopPropagationTextIntent(),
  };

  static Map<ShortcutActivator, Intent> get _shortcuts {
    if (kIsWeb) {
      return _webShortcuts;
    }

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
}
