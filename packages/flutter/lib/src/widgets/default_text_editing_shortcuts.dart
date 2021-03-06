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
/// lower in the widget tree than this. See [DefaultTextEditingActions] for an example
/// of remapping a text editing [Intent] to a custom [Action].
///
/// {@tool snippet}
///
/// This example shows how to use an additional [Shortcuts] widget to override
/// some default text editing keyboard shortcuts to have new behavior. Instead
/// of moving the cursor, alt + up/down will instead change the focused widget.
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: Shortcuts(
///         shortcuts: <LogicalKeySet, Intent>{
///           LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): NextFocusIntent(),
///           LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
///         },
///         child: Column(
///           children: <Widget>[
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
/// default text editing shortcuts to have completely custom behavior. Here, the
/// up/down arrow keys increment/decrement a counter instead of moving the
/// cursor.
///
/// ```dart
/// class IncrementCounterIntent extends Intent {}
/// class DecrementCounterIntent extends Intent {}
///
/// class MyWidget extends StatefulWidget {
///   MyWidget({ Key? key }) : super(key: key);
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
///     return Scaffold(
///       body: Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: <Widget>[
///             Text(
///               'You have pushed the button this many times:',
///             ),
///             Text(
///               '$_counter',
///               style: Theme.of(context).textTheme.headline4,
///             ),
///             Shortcuts(
///               shortcuts: <LogicalKeySet, Intent>{
///                 LogicalKeySet(LogicalKeyboardKey.arrowUp): IncrementCounterIntent(),
///                 LogicalKeySet(LogicalKeyboardKey.arrowDown): DecrementCounterIntent(),
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
///                 child: TextField(
///                   maxLines: 2,
///                   decoration: InputDecoration(
///                     hintText: 'Up/down increment/decrement here.',
///                   ),
///                 ),
///               ),
///             ),
///             TextField(
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
///  * [DefaultTextEditingActions], which contains all of the [Action]s that respond
///    to the [Intent]s in these shortcuts with the default text editing
///    behavior.
class DefaultTextEditingShortcuts extends StatelessWidget {
  /// Creates an instance of DefaultTextEditingShortcuts.
  const DefaultTextEditingShortcuts({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child [Widget].
  final Widget child;

  static final Map<LogicalKeySet, Intent> _androidShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionUpTextIntent(),
    // End has no effect on text editing on this platform.
    // Home has no effect on text editing on this platform.
    // Meta + arrow down has no effect on text editing on this platform.
    // Meta + arrow left has no effect on text editing on this platform.
    // Meta + arrow right has no effect on text editing on this platform.
    // Meta + arrow up has no effect on text editing on this platform.
    // Meta + shift + arrow down has no effect on text editing on this platform.
    // Meta + shift + arrow left has no effect on text editing on this platform.
    // Meta + shift + arrow right has no effect on text editing on this platform.
    // Meta + shift + arrow up has no effect on text editing on this platform.
    // Shift + end has no effect on text editing on this platform.
    // Shift + home has no effect on text editing on this platform.
  };

  static final Map<LogicalKeySet, Intent> _fuchsiaShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionUpTextIntent(),
    // Meta + arrow down has no effect on text editing on this platform.
    // End has no effect on text editing on this platform.
    // Home has no effect on text editing on this platform.
    // Meta + arrow left has no effect on text editing on this platform.
    // Meta + arrow right has no effect on text editing on this platform.
    // Meta + arrow up has no effect on text editing on this platform.
    // Meta + shift + arrow down has no effect on text editing on this platform.
    // Meta + shift + arrow left has no effect on text editing on this platform.
    // Meta + shift + arrow right has no effect on text editing on this platform.
    // Meta + shift + arrow up has no effect on text editing on this platform.
    // Shift + end has no effect on text editing on this platform.
    // Shift + home has no effect on text editing on this platform.
  };

  static final Map<LogicalKeySet, Intent> _iOSShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionUpTextIntent(),
    // Meta + arrow down has no effect on text editing on this platform.
    // End has no effect on text editing on this platform.
    // Home has no effect on text editing on this platform.
    // Meta + arrow left has no effect on text editing on this platform.
    // Meta + arrow right has no effect on text editing on this platform.
    // Meta + arrow up has no effect on text editing on this platform.
    // Meta + shift + arrow down has no effect on text editing on this platform.
    // Meta + shift + arrow left has no effect on text editing on this platform.
    // Meta + shift + arrow right has no effect on text editing on this platform.
    // Meta + shift + arrow up has no effect on text editing on this platform.
    // Shift + end has no effect on text editing on this platform.
    // Shift + home has no effect on text editing on this platform.
  };

  static final Map<LogicalKeySet, Intent> _linuxShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionUpTextIntent(),
    // Meta + arrow down has no effect on text editing on this platform.
    // End has no effect on text editing on this platform.
    // Home has no effect on text editing on this platform.
    // Meta + arrow left has no effect on text editing on this platform.
    // Meta + arrow right has no effect on text editing on this platform.
    // Meta + arrow up has no effect on text editing on this platform.
    // Meta + shift + arrow down has no effect on text editing on this platform.
    // Meta + shift + arrow left has no effect on text editing on this platform.
    // Meta + shift + arrow right has no effect on text editing on this platform.
    // Meta + shift + arrow up has no effect on text editing on this platform.
    // Shift + end has no effect on text editing on this platform.
    // Shift + home has no effect on text editing on this platform.
  };

  static final Map<LogicalKeySet, Intent> _macShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown): const MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp): const MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionUpTextIntent(),
    // Control + arrow left has no effect on text editing on this platform.
    // Control + arrow right has no effect on text editing on this platform.
    // Control + shift + arrow left has no effect on text editing on this platform.
    // Control + shift + arrow right has no effect on text editing on this platform.
    // End has no effect on text editing on this platform.
    // Home has no effect on text editing on this platform.
    // Shift + end has no effect on text editing on this platform.
    // Shift + home has no effect on text editing on this platform.
  };

  static final Map<LogicalKeySet, Intent> _windowsShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const MoveSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const MoveSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExpandSelectionToEndTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExpandSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExpandSelectionToStartTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): const MoveSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): const MoveSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightByWordTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.end): const MoveSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.home): const MoveSelectionLeftByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): const ExtendSelectionDownTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): const ExtendSelectionLeftTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): const ExtendSelectionRightTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): const ExtendSelectionUpTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.end): const ExpandSelectionRightByLineTextIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.home): const ExpandSelectionLeftByLineTextIntent(),
    // Meta + arrow down has no effect on text editing on this platform.
    // Meta + arrow left has no effect on text editing on this platform.
    // Meta + arrow right has no effect on text editing on this platform.
    // Meta + arrow up has no effect on text editing on this platform.
    // Meta + shift + arrow down has no effect on text editing on this platform.
    // Meta + shift + arrow left has no effect on text editing on this platform.
    // Meta + shift + arrow right has no effect on text editing on this platform.
    // Meta + shift + arrow up has no effect on text editing on this platform.
  };

  // Web handles its text selection natively and doesn't use any of these
  // shortcuts in Flutter.
  static final Map<LogicalKeySet, Intent> _webShortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.end): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.home): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.end): DoNothingAndStopPropagationIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.home): DoNothingAndStopPropagationIntent(),
  };

  static Map<LogicalKeySet, Intent> get _shortcuts {
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

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      debugLabel: '<Default Text Editing Shortcuts>',
      shortcuts: _shortcuts,
      child: child,
    );
  }
}
