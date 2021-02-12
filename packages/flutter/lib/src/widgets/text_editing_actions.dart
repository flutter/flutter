// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'actions.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'text_editing_action.dart';
import 'text_editing_intents.dart';

// TODO(justinmc): Update these examples now that the naming has changed.
/// An [Actions] widget that handles the default text editing behavior for
/// Flutter on the current platform.
///
/// This default behavior can be overridden by placing an [Actions] widget lower
/// in the widget tree than this. See [TextEditingShortcuts] for an example of
/// remapping keyboard keys to an existing text editing [Intent].
///
/// {@tool snippet}
///
/// This example shows how to use an additional [Actions] widget to override
/// the left arrow key [Intent] and make it move the cursor to the right
/// instead.
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
///       child: Actions(
///         actions: <Type, Action<Intent>>{
///           ArrowLeftTextIntent: TextEditingAction<ArrowLeftTextIntent>(
///             onInvoke: (ArrowLeftTextIntent intent, EditableTextState editableTextState) {
///               editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
///             },
///           ),
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
///   * [TextEditingShortcuts], which maps keyboard keys to many of the
///     [Intent]s that are handled here.
class TextEditingActions extends StatelessWidget {
  /// Creates an instance of TextEditingActions.
  TextEditingActions({
    Key? key,
    Map<Type, Action<Intent>>? additionalActions,
    required this.child,
  }) : additionalActions = additionalActions ?? <Type, Action<Intent>>{},
       super(key: key);

  /// The child [Widget] of TextEditingActions.
  final Widget child;

  /// The actions to be merged with the default text editing actions.
  ///
  /// The default text editing actions will override any conflicting keys in
  /// additionalActions. To override the default text editing actions, use an
  /// [Actions] Widget in the tree below this Widget.
  final Map<Type, Action<Intent>> additionalActions;

  // TODO(justinmc): Can I just use the "Intent" type  here? Is that not using
  // this as intended?
  static final TextEditingAction<Intent> _expandSelectionLeftByLineAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _expandSelectionRightByLineAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _expandSelectionToEndAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _expandSelectionToStartAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionDownAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionLeftAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionRightAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionUpAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionLeftByLineAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionLeftByWordAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionRightByLineAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _extendSelectionRightByWordAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionDown = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionLeft = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionRight = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionUp = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionLeftByLineAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionLeftByWordAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionRightByLineAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionRightByWordAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionToEndAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<Intent> _moveSelectionToStartAction = TextEditingAction<Intent>(
    onInvoke: (Intent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
    }
  );

  static final Map<Type, Action<Intent>> _androidActions = <Type, Action<Intent>>{
    // ShiftEndTextIntent is not handled by this platform.
    // ShiftHomeTextIntent is not handled by this platform.
  };

  static final Map<Type, Action<Intent>> _fuchsiaActions = <Type, Action<Intent>>{
    // ShiftEndTextIntent is not handled by this platform.
    // ShiftHomeTextIntent is not handled by this platform.
  };

  static final Map<Type, Action<Intent>> _iOSActions = <Type, Action<Intent>>{
    // ShiftEndTextIntent is not handled by this platform.
    // ShiftHomeTextIntent is not handled by this platform.
  };

  static final Map<Type, Action<Intent>> _linuxActions = <Type, Action<Intent>>{
    // ShiftEndTextIntent is not handled by this platform.
    // ShiftHomeTextIntent is not handled by this platform.
  };

  static final Map<Type, Action<Intent>> _macActions = <Type, Action<Intent>>{
    // ShiftEndTextIntent is not handled by this platform.
    // ShiftHomeTextIntent is not handled by this platform.
  };

  static final Map<Type, Action<Intent>> _windowsActions = <Type, Action<Intent>>{
    ShiftEndTextIntent: _expandSelectionRightByLineAction,
    ShiftHomeTextIntent: _expandSelectionLeftByLineAction,
  };

  // These Intents are triggered by TextEditingShortcuts. They are included
  // regardless of the platform; it's up to TextEditingShortcuts to decide which
  // are called on which platform.
  static final Map<Type, Action<Intent>> _shortcutsActions = <Type, Action<Intent>>{
    ExtendSelectionDownTextIntent: _extendSelectionDownAction,
    ExpandSelectionLeftByLineTextIntent: _expandSelectionLeftByLineAction,
    ExpandSelectionRightByLineTextIntent: _expandSelectionRightByLineAction,
    ExtendSelectionLeftTextIntent: _extendSelectionLeftAction,
    ExpandSelectionToEndTextIntent: _expandSelectionToEndAction,
    ExpandSelectionToStartTextIntent: _expandSelectionToStartAction,
    ExtendSelectionLeftByWordTextIntent: _extendSelectionLeftByWordAction,
    ExtendSelectionRightByWordTextIntent: _extendSelectionRightByWordAction,
    ExtendSelectionRightTextIntent: _extendSelectionRightAction,
    ExtendSelectionUpTextIntent: _extendSelectionUpAction,
    MoveSelectionDownTextIntent: _moveSelectionDown,
    MoveSelectionLeftTextIntent: _moveSelectionLeft,
    MoveSelectionLeftByLineTextIntent: _moveSelectionLeftByLineAction,
    MoveSelectionLeftByWordTextIntent: _moveSelectionLeftByWordAction,
    MoveSelectionRightTextIntent: _moveSelectionRight,
    MoveSelectionRightByLineTextIntent: _moveSelectionRightByLineAction,
    MoveSelectionRightByWordTextIntent: _moveSelectionRightByWordAction,
    MoveSelectionToEndTextIntent: _moveSelectionToEndAction,
    MoveSelectionToStartTextIntent: _moveSelectionToStartAction,
    MoveSelectionUpTextIntent: _moveSelectionUp,
  };

  static Map<Type, Action<Intent>> get _actions {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidActions;
      case TargetPlatform.fuchsia:
        return _fuchsiaActions;
      case TargetPlatform.iOS:
        return _iOSActions;
      case TargetPlatform.linux:
        return _linuxActions;
      case TargetPlatform.macOS:
        return _macActions;
      case TargetPlatform.windows:
        return _windowsActions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ...additionalActions,
        ..._shortcutsActions,
        ..._actions,
      },
      child: child,
    );
  }
}
