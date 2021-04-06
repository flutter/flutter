// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
///   * [WidgetsApp], which creates a DefaultTextEditingShortcuts.
class DefaultTextEditingActions extends Actions{
  /// Creates an instance of DefaultTextEditingActions.
  DefaultTextEditingActions({
    Key? key,
    required Widget child,
  }) : super(
    key: key,
    actions: _shortcutsActions,
    child: child,
  );

  // These Intents are triggered by DefaultTextEditingShortcuts. They are included
  // regardless of the platform; it's up to DefaultTextEditingShortcuts to decide which
  // are called on which platform.
  static final Map<Type, Action<Intent>> _shortcutsActions = <Type, Action<Intent>>{
    DoNothingAndStopPropagationTextIntent: _DoNothingAndStopPropagationTextAction(),
    ExtendSelectionDownTextIntent: _ExtendSelectionDownTextAction(),
    ExtendSelectionLeftByLineTextIntent: _ExtendSelectionLeftByLineTextAction(),
    ExtendSelectionLeftByWordTextIntent: _ExtendSelectionLeftByWordTextAction(),
    ExtendSelectionLeftByWordAndStopAtReversalTextIntent: _ExtendSelectionLeftByWordAndStopAtReversalTextAction(),
    ExtendSelectionLeftTextIntent: _ExtendSelectionLeftTextAction(),
    ExtendSelectionRightByWordAndStopAtReversalTextIntent: _ExtendSelectionRightByWordAndStopAtReversalTextAction(),
    ExtendSelectionRightByWordTextIntent: _ExtendSelectionRightByWordTextAction(),
    ExtendSelectionRightByLineTextIntent: _ExtendSelectionRightByLineTextAction(),
    ExtendSelectionRightTextIntent: _ExtendSelectionRightTextAction(),
    ExtendSelectionUpTextIntent: _ExtendSelectionUpTextAction(),
    ExpandSelectionLeftByLineTextIntent: _ExpandSelectionLeftByLineTextAction(),
    ExpandSelectionRightByLineTextIntent: _ExpandSelectionRightByLineTextAction(),
    ExpandSelectionToEndTextIntent: _ExpandSelectionToEndTextAction(),
    ExpandSelectionToStartTextIntent: _ExpandSelectionToStartTextAction(),
    MoveSelectionDownTextIntent: _MoveSelectionDownTextAction(),
    MoveSelectionLeftByLineTextIntent: _MoveSelectionLeftByLineTextAction(),
    MoveSelectionLeftByWordTextIntent: _MoveSelectionLeftByWordTextAction(),
    MoveSelectionLeftTextIntent: _MoveSelectionLeftTextAction(),
    MoveSelectionRightByLineTextIntent: _MoveSelectionRightByLineTextAction(),
    MoveSelectionRightByWordTextIntent: _MoveSelectionRightByWordTextAction(),
    MoveSelectionRightTextIntent: _MoveSelectionRightTextAction(),
    MoveSelectionToEndTextIntent: _MoveSelectionToEndTextAction(),
    MoveSelectionToStartTextIntent: _MoveSelectionToStartTextAction(),
    MoveSelectionUpTextIntent: _MoveSelectionUpTextAction(),
  };
}

// This allows the web engine to handle text editing events natively while using
// the same TextEditingAction logic to only handle events from a
// TextEditingTarget.
class _DoNothingAndStopPropagationTextAction extends TextEditingAction<DoNothingAndStopPropagationTextIntent> {
  _DoNothingAndStopPropagationTextAction();

  @override
  bool consumesKey(Intent intent) => false;

  @override
  void invoke(DoNothingAndStopPropagationTextIntent intent, [BuildContext? context]) {}
}

class _ExpandSelectionLeftByLineTextAction extends TextEditingAction<ExpandSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(ExpandSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionRightByLineTextAction extends TextEditingAction<ExpandSelectionRightByLineTextIntent> {
  @override
  Object? invoke(ExpandSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionToEndTextAction extends TextEditingAction<ExpandSelectionToEndTextIntent> {
  @override
  Object? invoke(ExpandSelectionToEndTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionToStartTextAction extends TextEditingAction<ExpandSelectionToStartTextIntent> {
  @override
  Object? invoke(ExpandSelectionToStartTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionDownTextAction extends TextEditingAction<ExtendSelectionDownTextIntent> {
  @override
  Object? invoke(ExtendSelectionDownTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionLeftByLineTextAction extends TextEditingAction<ExtendSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionLeftByWordAndStopAtReversalTextAction extends TextEditingAction<ExtendSelectionLeftByWordAndStopAtReversalTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByWordAndStopAtReversalTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false, true);
  }
}

class _ExtendSelectionLeftByWordTextAction extends TextEditingAction<ExtendSelectionLeftByWordTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
  }
}

class _ExtendSelectionLeftTextAction extends TextEditingAction<ExtendSelectionLeftTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionRightByLineTextAction extends TextEditingAction<ExtendSelectionRightByLineTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionRightByWordAndStopAtReversalTextAction extends TextEditingAction<ExtendSelectionRightByWordAndStopAtReversalTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByWordAndStopAtReversalTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false, true);
  }
}

class _ExtendSelectionRightByWordTextAction extends TextEditingAction<ExtendSelectionRightByWordTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
  }
}

class _ExtendSelectionRightTextAction extends TextEditingAction<ExtendSelectionRightTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionUpTextAction extends TextEditingAction<ExtendSelectionUpTextIntent> {
  @override
  Object? invoke(ExtendSelectionUpTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionDownTextAction extends TextEditingAction<MoveSelectionDownTextIntent> {
  @override
  Object? invoke(MoveSelectionDownTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftTextAction extends TextEditingAction<MoveSelectionLeftTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionRightTextAction extends TextEditingAction<MoveSelectionRightTextIntent> {
  @override
  Object? invoke(MoveSelectionRightTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionUpTextAction extends TextEditingAction<MoveSelectionUpTextIntent> {
  @override
  Object? invoke(MoveSelectionUpTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftByLineTextAction extends TextEditingAction<MoveSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftByWordTextAction extends TextEditingAction<MoveSelectionLeftByWordTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
  }
}

class _MoveSelectionRightByLineTextAction extends TextEditingAction<MoveSelectionRightByLineTextIntent> {
  @override
  Object? invoke(MoveSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionRightByWordTextAction extends TextEditingAction<MoveSelectionRightByWordTextIntent> {
  @override
  Object? invoke(MoveSelectionRightByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
  }
}

class _MoveSelectionToEndTextAction extends TextEditingAction<MoveSelectionToEndTextIntent> {
  @override
  Object? invoke(MoveSelectionToEndTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionToStartTextAction extends TextEditingAction<MoveSelectionToStartTextIntent> {
  @override
  Object? invoke(MoveSelectionToStartTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
  }
}
