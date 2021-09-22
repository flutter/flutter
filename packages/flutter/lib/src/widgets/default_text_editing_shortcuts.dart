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
/// lower in the widget tree than this. See [DefaultTextEditingActions] for an example
/// of remapping a text editing [Intent] to a custom [Action].
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
///   * [DefaultTextEditingActions], which contains all of the [Action]s that
///     respond to the [Intent]s in these shortcuts with the default text editing
///     behavior.
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

  static const Map<ShortcutActivator, Intent> _androidShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DeleteByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteForwardTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DeleteForwardByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteForwardByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): MoveSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): MoveSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExpandSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): MoveSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): MoveSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): ExtendSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): ExtendSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CutSelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllTextIntent(),
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
  };

  static const Map<ShortcutActivator, Intent> _fuchsiaShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DeleteByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteForwardTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DeleteForwardByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteForwardByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): MoveSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): MoveSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExpandSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): MoveSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): MoveSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): ExtendSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): ExtendSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CutSelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllTextIntent(),
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
  };

  static const Map<ShortcutActivator, Intent> _iOSShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DeleteByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteForwardTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DeleteForwardByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteForwardByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): MoveSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): MoveSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExpandSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): MoveSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): MoveSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): ExtendSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): ExtendSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CutSelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllTextIntent(),
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
  };

  static const Map<ShortcutActivator, Intent> _linuxShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DeleteByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteForwardTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DeleteForwardByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteForwardByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): MoveSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): MoveSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExpandSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): MoveSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): MoveSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): ExtendSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): ExtendSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.end): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.home): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.end, shift: true): ExtendSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.home, shift: true): ExtendSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CutSelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllTextIntent(),
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

  static const Map<ShortcutActivator, Intent> _macShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, meta: true): DeleteByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteForwardTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteForwardByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, meta: true): DeleteForwardByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): MoveSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): MoveSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExtendSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExtendSelectionLeftByWordAndStopAtReversalTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExtendSelectionRightByWordAndStopAtReversalTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExtendSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): MoveSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): MoveSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, meta: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, meta: true): ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, meta: true): ExpandSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.end, shift: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.home, shift: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, meta: true): CutSelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, meta: true): CopySelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, meta: true): PasteTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, meta: true): SelectAllTextIntent(),
    // The following key combinations have no effect on text editing on this
    // platform:
    //   * Control + X
    //   * Control + C
    //   * Control + V
    //   * Control + A
    //   * Control + arrow left
    //   * Control + arrow right
    //   * Control + shift + arrow left
    //   * Control + shift + arrow right
    //   * End
    //   * Home
    //   * Control + delete
    //   * Control + backspace
  };

  static const Map<ShortcutActivator, Intent> _windowsShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.backspace): DeleteTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, control: true): DeleteByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, alt: true): DeleteByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteForwardTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, control: true): DeleteForwardByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.delete, alt: true): DeleteForwardByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): MoveSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): MoveSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): ExpandSelectionToEndTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): ExpandSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): ExpandSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): ExpandSelectionToStartTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): MoveSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): MoveSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): MoveSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true): MoveSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): ExtendSelectionLeftByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): ExtendSelectionRightByWordTextIntent(),
    SingleActivator(LogicalKeyboardKey.end): MoveSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.home): MoveSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): ExtendSelectionDownTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionLeftTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionRightTextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): ExtendSelectionUpTextIntent(),
    SingleActivator(LogicalKeyboardKey.end, shift: true): ExtendSelectionRightByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.home, shift: true): ExtendSelectionLeftByLineTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CutSelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteTextIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllTextIntent(),
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
