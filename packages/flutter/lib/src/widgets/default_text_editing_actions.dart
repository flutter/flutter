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

/// An [Actions] widget that handles the default text editing behavior for
/// Flutter on the current platform.
///
/// This default behavior can be overridden by placing an [Actions] widget lower
/// in the widget tree than this. See [DefaultTextEditingShortcuts] for an example of
/// remapping keyboard keys to an existing text editing [Intent].
///
/// See also:
///
///   * [DefaultTextEditingShortcuts], which maps keyboard keys to many of the
///     [Intent]s that are handled here.
class DefaultTextEditingActions extends StatelessWidget {
  /// Creates an instance of DefaultTextEditingActions.
  const DefaultTextEditingActions({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child [Widget] of DefaultTextEditingActions.
  final Widget child;

  static final TextEditingAction<ExpandSelectionLeftByLineTextIntent> _expandSelectionLeftByLineAction = TextEditingAction<ExpandSelectionLeftByLineTextIntent>(
    onInvoke: (ExpandSelectionLeftByLineTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExpandSelectionRightByLineTextIntent> _expandSelectionRightByLineAction = TextEditingAction<ExpandSelectionRightByLineTextIntent>(
    onInvoke: (ExpandSelectionRightByLineTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExpandSelectionToEndTextIntent> _expandSelectionToEndAction = TextEditingAction<ExpandSelectionToEndTextIntent>(
    onInvoke: (ExpandSelectionToEndTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExpandSelectionToStartTextIntent> _expandSelectionToStartAction = TextEditingAction<ExpandSelectionToStartTextIntent>(
    onInvoke: (ExpandSelectionToStartTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionDownTextIntent> _extendSelectionDownAction = TextEditingAction<ExtendSelectionDownTextIntent>(
    onInvoke: (ExtendSelectionDownTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionLeftByLineTextIntent> _extendSelectionLeftByLineAction = TextEditingAction<ExtendSelectionLeftByLineTextIntent>(
    onInvoke: (ExtendSelectionLeftByLineTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionLeftByWordTextIntent> _extendSelectionLeftByWordAction = TextEditingAction<ExtendSelectionLeftByWordTextIntent>(
    onInvoke: (ExtendSelectionLeftByWordTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
    }
  );

  static final TextEditingAction<ExtendSelectionLeftTextIntent> _extendSelectionLeftAction = TextEditingAction<ExtendSelectionLeftTextIntent>(
    onInvoke: (ExtendSelectionLeftTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionRightByLineTextIntent> _extendSelectionRightByLineAction = TextEditingAction<ExtendSelectionRightByLineTextIntent>(
    onInvoke: (ExtendSelectionRightByLineTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionRightByWordTextIntent> _extendSelectionRightByWordAction = TextEditingAction<ExtendSelectionRightByWordTextIntent>(
    onInvoke: (ExtendSelectionRightByWordTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
    }
  );

  static final TextEditingAction<ExtendSelectionRightTextIntent> _extendSelectionRightAction = TextEditingAction<ExtendSelectionRightTextIntent>(
    onInvoke: (ExtendSelectionRightTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<ExtendSelectionUpTextIntent> _extendSelectionUpAction = TextEditingAction<ExtendSelectionUpTextIntent>(
    onInvoke: (ExtendSelectionUpTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionDownTextIntent> _moveSelectionDown = TextEditingAction<MoveSelectionDownTextIntent>(
    onInvoke: (MoveSelectionDownTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionLeftTextIntent> _moveSelectionLeft = TextEditingAction<MoveSelectionLeftTextIntent>(
    onInvoke: (MoveSelectionLeftTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionRightTextIntent> _moveSelectionRight = TextEditingAction<MoveSelectionRightTextIntent>(
    onInvoke: (MoveSelectionRightTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionUpTextIntent> _moveSelectionUp = TextEditingAction<MoveSelectionUpTextIntent>(
    onInvoke: (MoveSelectionUpTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionLeftByLineTextIntent> _moveSelectionLeftByLineAction = TextEditingAction<MoveSelectionLeftByLineTextIntent>(
    onInvoke: (MoveSelectionLeftByLineTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionLeftByWordTextIntent> _moveSelectionLeftByWordAction = TextEditingAction<MoveSelectionLeftByWordTextIntent>(
    onInvoke: (MoveSelectionLeftByWordTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
    }
  );

  static final TextEditingAction<MoveSelectionRightByLineTextIntent> _moveSelectionRightByLineAction = TextEditingAction<MoveSelectionRightByLineTextIntent>(
    onInvoke: (MoveSelectionRightByLineTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionRightByWordTextIntent> _moveSelectionRightByWordAction = TextEditingAction<MoveSelectionRightByWordTextIntent>(
    onInvoke: (MoveSelectionRightByWordTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
    }
  );

  static final TextEditingAction<MoveSelectionToEndTextIntent> _moveSelectionToEndAction = TextEditingAction<MoveSelectionToEndTextIntent>(
    onInvoke: (MoveSelectionToEndTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
    }
  );

  static final TextEditingAction<MoveSelectionToStartTextIntent> _moveSelectionToStartAction = TextEditingAction<MoveSelectionToStartTextIntent>(
    onInvoke: (MoveSelectionToStartTextIntent intent, TextEditingActionTarget textEditingActionTarget) {
      textEditingActionTarget.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
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

  // These Intents are triggered by DefaultTextEditingShortcuts. They are included
  // regardless of the platform; it's up to DefaultTextEditingShortcuts to decide which
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
        ..._shortcutsActions,
        ..._actions,
      },
      child: child,
    );
  }
}
