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
class DefaultTextEditingActions extends Actions {
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
    DeleteTextIntent: _DeleteTextAction(),
    DeleteByWordTextIntent: _DeleteByWordTextAction(),
    DeleteByLineTextIntent: _DeleteByLineTextAction(),
    DeleteForwardTextIntent: _DeleteForwardTextAction(),
    DeleteForwardByWordTextIntent: _DeleteForwardByWordTextAction(),
    DeleteForwardByLineTextIntent: _DeleteForwardByLineTextAction(),
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
    SelectAllTextIntent: _SelectAllTextAction(),
    CopySelectionTextIntent: _CopySelectionTextAction(),
    CutSelectionTextIntent: _CutSelectionTextAction(),
    PasteTextIntent: _PasteTextAction(),
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

class _DeleteTextAction extends TextEditingAction<DeleteTextIntent> {
  @override
  Object? invoke(DeleteTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.delete(SelectionChangedCause.keyboard);
  }
}

class _DeleteByWordTextAction extends TextEditingAction<DeleteByWordTextIntent> {
  @override
  Object? invoke(DeleteByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.deleteByWord(SelectionChangedCause.keyboard, false);
  }
}

class _DeleteByLineTextAction extends TextEditingAction<DeleteByLineTextIntent> {
  @override
  Object? invoke(DeleteByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.deleteByLine(SelectionChangedCause.keyboard);
  }
}

class _DeleteForwardTextAction extends TextEditingAction<DeleteForwardTextIntent> {
  @override
  Object? invoke(DeleteForwardTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.deleteForward(SelectionChangedCause.keyboard);
  }
}

class _DeleteForwardByWordTextAction extends TextEditingAction<DeleteForwardByWordTextIntent> {
  @override
  Object? invoke(DeleteForwardByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.deleteForwardByWord(SelectionChangedCause.keyboard, false);
  }
}

class _DeleteForwardByLineTextAction extends TextEditingAction<DeleteForwardByLineTextIntent> {
  @override
  Object? invoke(DeleteForwardByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.deleteForwardByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionLeftByLineTextAction extends TextEditingAction<ExpandSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(ExpandSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionRightByLineTextAction extends TextEditingAction<ExpandSelectionRightByLineTextIntent> {
  @override
  Object? invoke(ExpandSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.expandSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionToEndTextAction extends TextEditingAction<ExpandSelectionToEndTextIntent> {
  @override
  Object? invoke(ExpandSelectionToEndTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.expandSelectionToEnd(SelectionChangedCause.keyboard);
  }
}

class _ExpandSelectionToStartTextAction extends TextEditingAction<ExpandSelectionToStartTextIntent> {
  @override
  Object? invoke(ExpandSelectionToStartTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.expandSelectionToStart(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionDownTextAction extends TextEditingAction<ExtendSelectionDownTextIntent> {
  @override
  Object? invoke(ExtendSelectionDownTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionDown(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionLeftByLineTextAction extends TextEditingAction<ExtendSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionLeftByWordAndStopAtReversalTextAction extends TextEditingAction<ExtendSelectionLeftByWordAndStopAtReversalTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByWordAndStopAtReversalTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false, true);
  }
}

class _ExtendSelectionLeftByWordTextAction extends TextEditingAction<ExtendSelectionLeftByWordTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
  }
}

class _ExtendSelectionLeftTextAction extends TextEditingAction<ExtendSelectionLeftTextIntent> {
  @override
  Object? invoke(ExtendSelectionLeftTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionLeft(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionRightByLineTextAction extends TextEditingAction<ExtendSelectionRightByLineTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionRightByWordAndStopAtReversalTextAction extends TextEditingAction<ExtendSelectionRightByWordAndStopAtReversalTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByWordAndStopAtReversalTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionRightByWord(SelectionChangedCause.keyboard, false, true);
  }
}

class _ExtendSelectionRightByWordTextAction extends TextEditingAction<ExtendSelectionRightByWordTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
  }
}

class _ExtendSelectionRightTextAction extends TextEditingAction<ExtendSelectionRightTextIntent> {
  @override
  Object? invoke(ExtendSelectionRightTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionRight(SelectionChangedCause.keyboard);
  }
}

class _ExtendSelectionUpTextAction extends TextEditingAction<ExtendSelectionUpTextIntent> {
  @override
  Object? invoke(ExtendSelectionUpTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.extendSelectionUp(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionDownTextAction extends TextEditingAction<MoveSelectionDownTextIntent> {
  @override
  Object? invoke(MoveSelectionDownTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionDown(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftTextAction extends TextEditingAction<MoveSelectionLeftTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionLeft(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionRightTextAction extends TextEditingAction<MoveSelectionRightTextIntent> {
  @override
  Object? invoke(MoveSelectionRightTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionRight(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionUpTextAction extends TextEditingAction<MoveSelectionUpTextIntent> {
  @override
  Object? invoke(MoveSelectionUpTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionUp(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftByLineTextAction extends TextEditingAction<MoveSelectionLeftByLineTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionLeftByWordTextAction extends TextEditingAction<MoveSelectionLeftByWordTextIntent> {
  @override
  Object? invoke(MoveSelectionLeftByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
  }
}

class _MoveSelectionRightByLineTextAction extends TextEditingAction<MoveSelectionRightByLineTextIntent> {
  @override
  Object? invoke(MoveSelectionRightByLineTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionRightByLine(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionRightByWordTextAction extends TextEditingAction<MoveSelectionRightByWordTextIntent> {
  @override
  Object? invoke(MoveSelectionRightByWordTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
  }
}

class _MoveSelectionToEndTextAction extends TextEditingAction<MoveSelectionToEndTextIntent> {
  @override
  Object? invoke(MoveSelectionToEndTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionToEnd(SelectionChangedCause.keyboard);
  }
}

class _MoveSelectionToStartTextAction extends TextEditingAction<MoveSelectionToStartTextIntent> {
  @override
  Object? invoke(MoveSelectionToStartTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.moveSelectionToStart(SelectionChangedCause.keyboard);
  }
}


class _SelectAllTextAction extends TextEditingAction<SelectAllTextIntent> {
  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.selectAll(SelectionChangedCause.keyboard);
  }
}

class _CopySelectionTextAction extends TextEditingAction<CopySelectionTextIntent> {
  @override
  Object? invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.copySelection(SelectionChangedCause.keyboard);
  }
}

class _CutSelectionTextAction extends TextEditingAction<CutSelectionTextIntent> {
  @override
  Object? invoke(CutSelectionTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.cutSelection(SelectionChangedCause.keyboard);
  }
}

class _PasteTextAction extends TextEditingAction<PasteTextIntent> {
  @override
  Object? invoke(PasteTextIntent intent, [BuildContext? context]) {
    textEditingActionTarget!.pasteText(SelectionChangedCause.keyboard);
  }
}
