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
///                       return null;
///                     },
///                   ),
///                   DecrementCounterIntent: CallbackAction<DecrementCounterIntent>(
///                     onInvoke: (DecrementCounterIntent intent) {
///                       setState(() {
///                         _counter--;
///                       });
///                       return null;
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
  static final Map<ShortcutActivator, Intent> _commonShortcuts = <ShortcutActivator, Intent>{
    // Delete Shortcuts.
    for (final bool pressShift in const <bool>[true, false])
      ...<SingleActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift): const DeleteCharacterIntent(forward: false),
        SingleActivator(LogicalKeyboardKey.backspace, control: true, shift: pressShift): const DeleteToNextWordBoundaryIntent(forward: false),
        SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift): const DeleteToLineBreakIntent(forward: false),
        SingleActivator(LogicalKeyboardKey.delete, shift: pressShift): const DeleteCharacterIntent(forward: true),
        SingleActivator(LogicalKeyboardKey.delete, control: true, shift: pressShift): const DeleteToNextWordBoundaryIntent(forward: true),
        SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift): const DeleteToLineBreakIntent(forward: true),
      },

    // Arrow: Move Selection.
    const SingleActivator(LogicalKeyboardKey.arrowLeft): const ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight): const ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowUp): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): const ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): const ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): const ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): const ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.keyX, control: true): const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
    const SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent.copy,
    const SingleActivator(LogicalKeyboardKey.keyV, control: true): const PasteTextIntent(SelectionChangedCause.keyboard),
    const SingleActivator(LogicalKeyboardKey.keyA, control: true): const SelectAllTextIntent(SelectionChangedCause.keyboard),
  };

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * End
  //   * Home
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + shift? + arrow down
  //   * Meta + shift? + arrow left
  //   * Meta + shift? + arrow right
  //   * Meta + shift? + arrow up
  //   * Shift + end
  //   * Shift + home
  //   * Meta + shift? + delete
  //   * Meta + shift? + backspace
  static final Map<ShortcutActivator, Intent> _androidShortcuts = _commonShortcuts;

  static final Map<ShortcutActivator, Intent> _fuchsiaShortcuts = _androidShortcuts;

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * End
  //   * Home
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + shift? + arrow down
  //   * Meta + shift? + arrow left
  //   * Meta + shift? + arrow right
  //   * Meta + shift? + arrow up
  //   * Shift + end
  //   * Shift + home
  //   * Meta + shift? + delete
  //   * Meta + shift? + backspace
  static final Map<ShortcutActivator, Intent> _iOSShortcuts = _commonShortcuts;

  static final Map<ShortcutActivator, Intent> _linuxShortcuts = <ShortcutActivator, Intent>{
    ..._commonShortcuts,
    const SingleActivator(LogicalKeyboardKey.home): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.end): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.home, shift: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.end, shift: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    // The following key combinations have no effect on text editing on this
    // platform:
    //   * Control + shift? + end
    //   * Control + shift? + home
    //   * Meta + X
    //   * Meta + C
    //   * Meta + V
    //   * Meta + A
    //   * Meta + shift? + arrow down
    //   * Meta + shift? + arrow left
    //   * Meta + shift? + arrow right
    //   * Meta + shift? + arrow up
    //   * Meta + shift? + delete
    //   * Meta + shift? + backspace
  };

  // macOS document shortcuts: https://support.apple.com/en-us/HT201236.
  // The macOS shortcuts uses different word/line modifiers than most other
  // platforms.
  static final Map<ShortcutActivator, Intent> _macShortcuts = <ShortcutActivator, Intent>{
    for (final bool pressShift in const <bool>[true, false])
      ...<SingleActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift): const DeleteCharacterIntent(forward: false),
        SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift): const DeleteToNextWordBoundaryIntent(forward: false),
        SingleActivator(LogicalKeyboardKey.backspace, meta: true, shift: pressShift): const DeleteToLineBreakIntent(forward: false),
        SingleActivator(LogicalKeyboardKey.delete, shift: pressShift): const DeleteCharacterIntent(forward: true),
        SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift): const DeleteToNextWordBoundaryIntent(forward: true),
        SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: pressShift): const DeleteToLineBreakIntent(forward: true),
      },

    const SingleActivator(LogicalKeyboardKey.arrowLeft): const ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight): const ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowUp): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),

    // Shift + Arrow: Extend Selection.
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): const ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): const ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): const ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): const ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): const ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(forward: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): const ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(forward: true),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false, collapseAtReversal: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false, collapseAtReversal: true),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true),

    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, meta: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, meta: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, meta: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.home, shift: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.end, shift: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),

    const SingleActivator(LogicalKeyboardKey.keyX, meta: true): const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
    const SingleActivator(LogicalKeyboardKey.keyC, meta: true): CopySelectionTextIntent.copy,
    const SingleActivator(LogicalKeyboardKey.keyV, meta: true): const PasteTextIntent(SelectionChangedCause.keyboard),
    const SingleActivator(LogicalKeyboardKey.keyA, meta: true): const SelectAllTextIntent(SelectionChangedCause.keyboard),
    // The following key combinations have no effect on text editing on this
    // platform:
    //   * End
    //   * Home
    //   * Control + shift? + end
    //   * Control + shift? + home
  };

  // The following key combinations have no effect on text editing on this
  // platform:
  //   * Meta + X
  //   * Meta + C
  //   * Meta + V
  //   * Meta + A
  //   * Meta + shift? + arrow down
  //   * Meta + shift? + arrow left
  //   * Meta + shift? + arrow right
  //   * Meta + shift? + arrow up
  //   * Meta + delete
  //   * Meta + backspace
  static final Map<ShortcutActivator, Intent> _windowsShortcuts = <ShortcutActivator, Intent>{
    ..._commonShortcuts,
    const SingleActivator(LogicalKeyboardKey.home): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.end): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.home, shift: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.end, shift: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.home, control: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.end, control: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true),
    const SingleActivator(LogicalKeyboardKey.home, shift: true, control: true): const ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false),
    const SingleActivator(LogicalKeyboardKey.end, shift: true, control: true): const ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false),
  };

  // Web handles its text selection natively and doesn't use any of these
  // shortcuts in Flutter.
  static final Map<ShortcutActivator, Intent> _webShortcuts = <ShortcutActivator, Intent>{
    for (final bool pressShift in const <bool>[true, false])
      ...<SingleActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.delete, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.backspace, control: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.delete, control: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.backspace, meta: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
        SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
      },
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.end): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.home): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.end, shift: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.home, shift: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.end, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.home, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.space): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyX, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyX, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyC, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyC, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyV, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyV, meta: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyA, control: true): const DoNothingAndStopPropagationTextIntent(),
    const SingleActivator(LogicalKeyboardKey.keyA, meta: true): const DoNothingAndStopPropagationTextIntent(),
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
