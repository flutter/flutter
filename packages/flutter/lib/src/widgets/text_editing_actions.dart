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

  static final TextEditingAction<ExpandSelectionLeftByLineTextIntent> _expandSelectionLeftByLineAction = TextEditingAction<ExpandSelectionLeftByLineTextIntent>(
    onInvoke: (ExpandSelectionLeftByLineTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExpandSelectionRightByLineTextIntent> _expandSelectionRightByLineAction = TextEditingAction<ExpandSelectionRightByLineTextIntent>(
    onInvoke: (ExpandSelectionRightByLineTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExpandSelectionToEndTextIntent> _expandSelectionToEndAction = TextEditingAction<ExpandSelectionToEndTextIntent>(
    onInvoke: (ExpandSelectionToEndTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExpandSelectionToStartTextIntent> _expandSelectionToStartAction = TextEditingAction<ExpandSelectionToStartTextIntent>(
    onInvoke: (ExpandSelectionToStartTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionDownTextIntent> _extendSelectionDownAction = TextEditingAction<ExtendSelectionDownTextIntent>(
    onInvoke: (ExtendSelectionDownTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionLeftTextIntent> _extendSelectionLeftAction = TextEditingAction<ExtendSelectionLeftTextIntent>(
    onInvoke: (ExtendSelectionLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionRightTextIntent> _extendSelectionRightAction = TextEditingAction<ExtendSelectionRightTextIntent>(
    onInvoke: (ExtendSelectionRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionUpTextIntent> _extendSelectionUpAction = TextEditingAction<ExtendSelectionUpTextIntent>(
    onInvoke: (ExtendSelectionUpTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionLeftByLineTextIntent> _extendSelectionLeftByLineAction = TextEditingAction<ExtendSelectionLeftByLineTextIntent>(
    onInvoke: (ExtendSelectionLeftByLineTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionLeftByWordTextIntent> _extendSelectionLeftByWordAction = TextEditingAction<ExtendSelectionLeftByWordTextIntent>(
    onInvoke: (ExtendSelectionLeftByWordTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionRightByLineTextIntent> _extendSelectionRightByLineAction = TextEditingAction<ExtendSelectionRightByLineTextIntent>(
    onInvoke: (ExtendSelectionRightByLineTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionRightByWordTextIntent> _extendSelectionRightByWordAction = TextEditingAction<ExtendSelectionRightByWordTextIntent>(
    onInvoke: (ExtendSelectionRightByWordTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionDownTextIntent> _moveSelectionDown = TextEditingAction<MoveSelectionDownTextIntent>(
    onInvoke: (MoveSelectionDownTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionLeftTextIntent> _moveSelectionLeft = TextEditingAction<MoveSelectionLeftTextIntent>(
    onInvoke: (MoveSelectionLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionRightTextIntent> _moveSelectionRight = TextEditingAction<MoveSelectionRightTextIntent>(
    onInvoke: (MoveSelectionRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionUpTextIntent> _moveSelectionUp = TextEditingAction<MoveSelectionUpTextIntent>(
    onInvoke: (MoveSelectionUpTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionLeftByLineTextIntent> _moveSelectionLeftByLineAction = TextEditingAction<MoveSelectionLeftByLineTextIntent>(
    onInvoke: (MoveSelectionLeftByLineTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionLeftByWordTextIntent> _moveSelectionLeftByWordAction = TextEditingAction<MoveSelectionLeftByWordTextIntent>(
    onInvoke: (MoveSelectionLeftByWordTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionRightByLineTextIntent> _moveSelectionRightByLineAction = TextEditingAction<MoveSelectionRightByLineTextIntent>(
    onInvoke: (MoveSelectionRightByLineTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionRightByWordTextIntent> _moveSelectionRightByWordAction = TextEditingAction<MoveSelectionRightByWordTextIntent>(
    onInvoke: (MoveSelectionRightByWordTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionToEndTextIntent> _moveSelectionToEndAction = TextEditingAction<MoveSelectionToEndTextIntent>(
    onInvoke: (MoveSelectionToEndTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionToStartTextIntent> _moveSelectionToStartAction = TextEditingAction<MoveSelectionToStartTextIntent>(
    onInvoke: (MoveSelectionToStartTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
    }
  );

  // TODO(justinmc): Put Actions here that are triggered directly, not by
  // Shortcuts.
  // https://github.com/flutter/flutter/issues/75004
  static final Map<Type, Action<Intent>> _androidActions = <Type, Action<Intent>>{
  };

  static final Map<Type, Action<Intent>> _fuchsiaActions = <Type, Action<Intent>>{
  };

  static final Map<Type, Action<Intent>> _iOSActions = <Type, Action<Intent>>{
  };

  static final Map<Type, Action<Intent>> _linuxActions = <Type, Action<Intent>>{
  };

  static final Map<Type, Action<Intent>> _macActions = <Type, Action<Intent>>{
  };

  static final Map<Type, Action<Intent>> _windowsActions = <Type, Action<Intent>>{
  };

  // These Intents are triggered by TextEditingShortcuts. They are included
  // regardless of the platform; it's up to TextEditingShortcuts to decide which
  // are called on which platform.
  static final Map<Type, Action<Intent>> _shortcutsActions = <Type, Action<Intent>>{
    ExtendSelectionDownTextIntent: _extendSelectionDownAction,
    ExtendSelectionLeftByLineTextIntent: _extendSelectionLeftByLineAction,
    ExtendSelectionLeftByWordTextIntent: _extendSelectionLeftByWordAction,
    ExtendSelectionLeftTextIntent: _extendSelectionLeftAction,
    ExtendSelectionRightByWordTextIntent: _extendSelectionRightByWordAction,
    ExtendSelectionRightByLineTextIntent: _extendSelectionRightByLineAction,
    ExtendSelectionRightTextIntent: _extendSelectionRightAction,
    ExtendSelectionUpTextIntent: _extendSelectionUpAction,
    ExpandSelectionLeftByLineTextIntent: _expandSelectionLeftByLineAction,
    ExpandSelectionRightByLineTextIntent: _expandSelectionRightByLineAction,
    ExpandSelectionToEndTextIntent: _expandSelectionToEndAction,
    ExpandSelectionToStartTextIntent: _expandSelectionToStartAction,
    MoveSelectionDownTextIntent: _moveSelectionDown,
    MoveSelectionLeftByLineTextIntent: _moveSelectionLeftByLineAction,
    MoveSelectionLeftByWordTextIntent: _moveSelectionLeftByWordAction,
    MoveSelectionLeftTextIntent: _moveSelectionLeft,
    MoveSelectionRightByLineTextIntent: _moveSelectionRightByLineAction,
    MoveSelectionRightByWordTextIntent: _moveSelectionRightByWordAction,
    MoveSelectionRightTextIntent: _moveSelectionRight,
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
