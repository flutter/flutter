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

/// An [Actions] Widget that handles the default  text editing behavior for
/// Flutter on the current platform.
///
/// This default behavior can be overridden by placing an [Actions] widget lower
/// in the Widget tree than this.
///
/// See also:
///
///   * [TextEditingIntent] and all of its subclasses, which comprise all of the
///     [Intent]s that are handle here.
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

  static final TextEditingAction<AltArrowLeftTextIntent> _altArrowLeftTextAction = TextEditingAction<AltArrowLeftTextIntent>(
    onInvoke: (AltArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<AltArrowRightTextIntent> _altArrowRightTextAction = TextEditingAction<AltArrowRightTextIntent>(
    onInvoke: (AltArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<AltShiftArrowLeftTextIntent> _altShiftArrowLeftTextAction = TextEditingAction<AltShiftArrowLeftTextIntent>(
    onInvoke: (AltShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<AltShiftArrowRightTextIntent> _altShiftArrowRightTextAction = TextEditingAction<AltShiftArrowRightTextIntent>(
    onInvoke: (AltShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<ControlShiftArrowLeftTextIntent> _controlShiftArrowLeftTextAction = TextEditingAction<ControlShiftArrowLeftTextIntent>(
    onInvoke: (ControlShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
          break;
      }
    },
  );

  static final TextEditingAction<ControlShiftArrowRightTextIntent> _controlShiftArrowRightTextAction = TextEditingAction<ControlShiftArrowRightTextIntent>(
    onInvoke: (ControlShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
          break;
      }
    },
  );

  static final TextEditingAction<MetaArrowDownTextIntent> _metaArrowDownTextAction = TextEditingAction<MetaArrowDownTextIntent>(
    onInvoke: (MetaArrowDownTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaArrowLeftTextIntent> _metaArrowLeftTextAction = TextEditingAction<MetaArrowLeftTextIntent>(
    onInvoke: (MetaArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaArrowRightTextIntent> _metaArrowRightTextAction = TextEditingAction<MetaArrowRightTextIntent>(
    onInvoke: (MetaArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaArrowUpTextIntent> _metaArrowUpTextAction = TextEditingAction<MetaArrowUpTextIntent>(
    onInvoke: (MetaArrowUpTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaShiftArrowDownTextIntent> _metaShiftArrowDownTextAction = TextEditingAction<MetaShiftArrowDownTextIntent>(
    onInvoke: (MetaShiftArrowDownTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaShiftArrowLeftTextIntent> _metaShiftArrowLeftTextAction = TextEditingAction<MetaShiftArrowLeftTextIntent>(
    onInvoke: (MetaShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaShiftArrowRightTextIntent> _metaShiftArrowRightTextAction = TextEditingAction<MetaShiftArrowRightTextIntent>(
    onInvoke: (MetaShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaShiftArrowUpTextIntent> _metaShiftArrowUpTextAction = TextEditingAction<MetaShiftArrowUpTextIntent>(
    onInvoke: (MetaShiftArrowUpTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          editableTextState.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<HomeTextIntent> _homeTextAction = TextEditingAction<HomeTextIntent>(
    onInvoke: (HomeTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  static final TextEditingAction<EndTextIntent> _endTextAction = TextEditingAction<EndTextIntent>(
    onInvoke: (EndTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  static final TextEditingAction<ArrowDownTextIntent> _arrowDownTextAction = TextEditingAction<ArrowDownTextIntent>(
    onInvoke: (ArrowDownTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ArrowLeftTextIntent> _arrowLeftTextAction = TextEditingAction<ArrowLeftTextIntent>(
    onInvoke: (ArrowLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ArrowRightTextIntent> _arrowRightTextAction = TextEditingAction<ArrowRightTextIntent>(
    onInvoke: (ArrowRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ArrowUpTextIntent> _arrowUpTextAction = TextEditingAction<ArrowUpTextIntent>(
    onInvoke: (ArrowUpTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ControlArrowLeftTextIntent> _controlArrowLeftTextAction = TextEditingAction<ControlArrowLeftTextIntent>(
    onInvoke: (ControlArrowLeftTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
          break;
      }
    },
  );

  static final TextEditingAction<ControlArrowRightTextIntent> _controlArrowRightTextAction = TextEditingAction<ControlArrowRightTextIntent>(
    onInvoke: (ControlArrowRightTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard);
          break;
      }
    },
  );

  static final TextEditingAction<ShiftArrowDownTextIntent> _shiftArrowDownTextAction = TextEditingAction<ShiftArrowDownTextIntent>(
    onInvoke: (ShiftArrowDownTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftArrowLeftTextIntent> _shiftArrowLeftTextAction = TextEditingAction<ShiftArrowLeftTextIntent>(
    onInvoke: (ShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftArrowRightTextIntent> _shiftArrowRightTextAction = TextEditingAction<ShiftArrowRightTextIntent>(
    onInvoke: (ShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftArrowUpTextIntent> _shiftArrowUpTextAction = TextEditingAction<ShiftArrowUpTextIntent>(
    onInvoke: (ShiftArrowUpTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftHomeTextIntent> _shiftHomeTextAction = TextEditingAction<ShiftHomeTextIntent>(
    onInvoke: (ShiftHomeTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  static final TextEditingAction<ShiftEndTextIntent> _shiftEndTextAction = TextEditingAction<ShiftEndTextIntent>(
    onInvoke: (ShiftEndTextIntent intent, EditableTextState editableTextState) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          editableTextState.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          break;
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ...additionalActions,
        AltArrowLeftTextIntent: _altArrowLeftTextAction,
        AltArrowRightTextIntent: _altArrowRightTextAction,
        AltShiftArrowLeftTextIntent: _altShiftArrowLeftTextAction,
        AltShiftArrowRightTextIntent: _altShiftArrowRightTextAction,
        ArrowDownTextIntent: _arrowDownTextAction,
        ArrowLeftTextIntent: _arrowLeftTextAction,
        ArrowRightTextIntent: _arrowRightTextAction,
        ArrowUpTextIntent: _arrowUpTextAction,
        ControlArrowLeftTextIntent: _controlArrowLeftTextAction,
        ControlArrowRightTextIntent: _controlArrowRightTextAction,
        ControlShiftArrowLeftTextIntent: _controlShiftArrowLeftTextAction,
        ControlShiftArrowRightTextIntent: _controlShiftArrowRightTextAction,
        EndTextIntent: _endTextAction,
        HomeTextIntent: _homeTextAction,
        MetaArrowDownTextIntent: _metaArrowDownTextAction,
        MetaArrowRightTextIntent: _metaArrowRightTextAction,
        MetaArrowLeftTextIntent: _metaArrowLeftTextAction,
        MetaArrowUpTextIntent: _metaArrowUpTextAction,
        MetaShiftArrowDownTextIntent: _metaShiftArrowDownTextAction,
        MetaShiftArrowLeftTextIntent: _metaShiftArrowLeftTextAction,
        MetaShiftArrowRightTextIntent: _metaShiftArrowRightTextAction,
        MetaShiftArrowUpTextIntent: _metaShiftArrowUpTextAction,
        ShiftArrowDownTextIntent: _shiftArrowDownTextAction,
        ShiftArrowLeftTextIntent: _shiftArrowLeftTextAction,
        ShiftArrowRightTextIntent: _shiftArrowRightTextAction,
        ShiftArrowUpTextIntent: _shiftArrowUpTextAction,
        ShiftHomeTextIntent: _shiftHomeTextAction,
        ShiftEndTextIntent: _shiftEndTextAction,
      },
      child: child,
    );
  }
}
