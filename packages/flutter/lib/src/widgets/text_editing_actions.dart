// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

import 'text_editing_action.dart';

/// An [Intent] related to editing text.
///
/// See also:
///
///   * [TextEditingAction], which is intended to be used with
///     TextEditingIntents.
class TextEditingIntent extends Intent {
  /// The [EditableTextState] that is currently focused.
  ///
  /// When used with [TextEditingAction], this is set automatically.
  late final EditableTextState editableTextState;
}

// TODO(justinmc): Maybe move these to a text_editing_intents.dart?
class AltArrowLeftTextIntent extends TextEditingIntent {}
class AltArrowRightTextIntent extends TextEditingIntent {}
class AltShiftArrowLeftTextIntent extends TextEditingIntent {}
class AltShiftArrowRightTextIntent extends TextEditingIntent {}
class ArrowDownTextIntent extends TextEditingIntent {}
class ArrowLeftTextIntent extends TextEditingIntent {}
class ArrowRightTextIntent extends TextEditingIntent {}
class ArrowUpTextIntent extends TextEditingIntent {}
class ControlATextIntent extends TextEditingIntent {}
class ControlArrowLeftTextIntent extends TextEditingIntent {}
class ControlArrowRightTextIntent extends TextEditingIntent {}
class ControlCTextIntent extends TextEditingIntent {}
class ControlShiftArrowLeftTextIntent extends TextEditingIntent {}
class ControlShiftArrowRightTextIntent extends TextEditingIntent {}
class DragSelectionEndTextIntent extends TextEditingIntent {}
class DragSelectionStartTextIntent extends TextEditingIntent {}
class DragSelectionUpdateTextIntent extends TextEditingIntent {}
class ForcePressEndTextIntent extends TextEditingIntent {}
class ForcePressStartTextIntent extends TextEditingIntent {}
class EndTextIntent extends TextEditingIntent {}
class HomeTextIntent extends TextEditingIntent {}
class MetaArrowDownTextIntent extends TextEditingIntent {}
class MetaArrowLeftTextIntent extends TextEditingIntent {}
class MetaArrowRightTextIntent extends TextEditingIntent {}
class MetaArrowUpTextIntent extends TextEditingIntent {}
class MetaShiftArrowDownTextIntent extends TextEditingIntent {}
class MetaShiftArrowLeftTextIntent extends TextEditingIntent {}
class MetaShiftArrowRightTextIntent extends TextEditingIntent {}
class MetaShiftArrowUpTextIntent extends TextEditingIntent {}
class MetaCTextIntent extends TextEditingIntent {}
class SingleLongTapEndTextIntent extends TextEditingIntent {}
class SingleLongTapMoveUpdateTextIntent extends TextEditingIntent {}
class SingleLongTapStartTextIntent extends TextEditingIntent {}
class SingleTapCancelTextIntent extends TextEditingIntent {}
class SingleTapUpTextIntent extends TextEditingIntent {
  SingleTapUpTextIntent({
    required this.details,
  });

  final TapUpDetails details;
}
class ShiftArrowDownTextIntent extends TextEditingIntent {}
class ShiftArrowLeftTextIntent extends TextEditingIntent {}
class ShiftArrowRightTextIntent extends TextEditingIntent {}
class ShiftArrowUpTextIntent extends TextEditingIntent {}
class ShiftEndTextIntent extends TextEditingIntent {}
class ShiftHomeTextIntent extends TextEditingIntent {}

/// The map of [Action]s that correspond to the default text editing behavior
/// for Flutter on the current platform.
///
/// See also:
///
/// * [Actions], which can be used to override this behavior.
class TextEditingActions extends StatelessWidget {
  /// Creates an instance of TextEditingActions.
  TextEditingActions({
    Key? key,
    // TODO(justinmc): Is additionalActions a good way to do this?
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

  static final TextEditingAction<SingleTapUpTextIntent> _singleTapUpTextAction = TextEditingAction<SingleTapUpTextIntent>(
    onInvoke: (SingleTapUpTextIntent intent) {
      intent.editableTextState.hideToolbar();
      if (intent.editableTextState.widget.selectionEnabled) {
        switch (defaultTargetPlatform) {
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            switch (intent.details.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
                // Precise devices should place the cursor at a precise position.
                intent.editableTextState.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
                break;
              case PointerDeviceKind.touch:
              case PointerDeviceKind.unknown:
                // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
                // of the word.
                intent.editableTextState.renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
                break;
            }
            break;
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            intent.editableTextState.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
            break;
        }
      }
      intent.editableTextState.requestKeyboard();
    },
  );

  static final TextEditingAction<AltArrowLeftTextIntent> _altArrowLeftTextAction = TextEditingAction<AltArrowLeftTextIntent>(
    onInvoke: (AltArrowLeftTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard, false);
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
    onInvoke: (AltArrowRightTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard, false);
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
    onInvoke: (AltShiftArrowLeftTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
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
    onInvoke: (AltShiftArrowRightTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
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
    onInvoke: (ControlShiftArrowLeftTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.extendSelectionLeftByWord(SelectionChangedCause.keyboard, false);
          break;
      }
    },
  );

  static final TextEditingAction<ControlShiftArrowRightTextIntent> _controlShiftArrowRightTextAction = TextEditingAction<ControlShiftArrowRightTextIntent>(
    onInvoke: (ControlShiftArrowRightTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.extendSelectionRightByWord(SelectionChangedCause.keyboard, false);
          break;
      }
    },
  );

  static final TextEditingAction<MetaArrowDownTextIntent> _metaArrowDownTextAction = TextEditingAction<MetaArrowDownTextIntent>(
    onInvoke: (MetaArrowDownTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.moveSelectionToEnd(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaArrowLeftTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaArrowRightTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaArrowUpTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.moveSelectionToStart(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaShiftArrowDownTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.expandSelectionToEnd(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaShiftArrowLeftTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaShiftArrowRightTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (MetaShiftArrowUpTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          intent.editableTextState.renderEditable.expandSelectionToStart(SelectionChangedCause.keyboard);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    },
  );

  static final TextEditingAction<MetaCTextIntent> _metaCTextAction = TextEditingAction<MetaCTextIntent>(
    onInvoke: (MetaCTextIntent intent) {
      // TODO(justinmc): This needs to be deduplicated with text_selection.dart.
      final TextSelectionDelegate delegate = intent.editableTextState.renderEditable.textSelectionDelegate;
      final TextEditingValue value = delegate.textEditingValue;
      Clipboard.setData(ClipboardData(
        text: value.selection.textInside(value.text),
      ));
      //clipboardStatus?.update();
      delegate.textEditingValue = TextEditingValue(
        text: value.text,
        selection: TextSelection.collapsed(offset: value.selection.end),
      );
      delegate.bringIntoView(delegate.textEditingValue.selection.extent);
      //delegate.hideToolbar();
    },
  );

  // TODO(justinmc): Notice that this does nearly the same thing as
  // MetaArrowLeftTextIntent, but for different platforms.
  static final TextEditingAction<HomeTextIntent> _homeTextAction = TextEditingAction<HomeTextIntent>(
    onInvoke: (HomeTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (EndTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (ArrowDownTextIntent intent) {
      intent.editableTextState.renderEditable.moveSelectionDown(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ArrowLeftTextIntent> _arrowLeftTextAction = TextEditingAction<ArrowLeftTextIntent>(
    onInvoke: (ArrowLeftTextIntent intent) {
      intent.editableTextState.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ArrowRightTextIntent> _arrowRightTextAction = TextEditingAction<ArrowRightTextIntent>(
    onInvoke: (ArrowRightTextIntent intent) {
      intent.editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ArrowUpTextIntent> _arrowUpTextAction = TextEditingAction<ArrowUpTextIntent>(
    onInvoke: (ArrowUpTextIntent intent) {
      intent.editableTextState.renderEditable.moveSelectionUp(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ControlCTextIntent> _controlCTextAction = TextEditingAction<ControlCTextIntent>(
    onInvoke: (ControlCTextIntent intent) {
      print('justin copy (with control, not command)');
    },
  );

  static final TextEditingAction<ControlATextIntent> _controlATextAction = TextEditingAction<ControlATextIntent>(
    onInvoke: (ControlATextIntent intent) {
      // TODO(justinmc): Select all.
    },
  );

  static final TextEditingAction<ControlArrowLeftTextIntent> _controlArrowLeftTextAction = TextEditingAction<ControlArrowLeftTextIntent>(
    onInvoke: (ControlArrowLeftTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
          break;
      }
    },
  );

  static final TextEditingAction<ControlArrowRightTextIntent> _controlArrowRightTextAction = TextEditingAction<ControlArrowRightTextIntent>(
    onInvoke: (ControlArrowRightTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.moveSelectionRightByWord(SelectionChangedCause.keyboard);
          break;
      }
    },
  );

  static final TextEditingAction<ShiftArrowDownTextIntent> _shiftArrowDownTextAction = TextEditingAction<ShiftArrowDownTextIntent>(
    onInvoke: (ShiftArrowDownTextIntent intent) {
      intent.editableTextState.renderEditable.extendSelectionDown(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftArrowLeftTextIntent> _shiftArrowLeftTextAction = TextEditingAction<ShiftArrowLeftTextIntent>(
    onInvoke: (ShiftArrowLeftTextIntent intent) {
      intent.editableTextState.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftArrowRightTextIntent> _shiftArrowRightTextAction = TextEditingAction<ShiftArrowRightTextIntent>(
    onInvoke: (ShiftArrowRightTextIntent intent) {
      intent.editableTextState.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftArrowUpTextIntent> _shiftArrowUpTextAction = TextEditingAction<ShiftArrowUpTextIntent>(
    onInvoke: (ShiftArrowUpTextIntent intent) {
      intent.editableTextState.renderEditable.extendSelectionUp(SelectionChangedCause.keyboard);
    },
  );

  static final TextEditingAction<ShiftHomeTextIntent> _shiftHomeTextAction = TextEditingAction<ShiftHomeTextIntent>(
    onInvoke: (ShiftHomeTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.expandSelectionLeftByLine(SelectionChangedCause.keyboard);
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
    onInvoke: (ShiftEndTextIntent intent) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          intent.editableTextState.renderEditable.expandSelectionRightByLine(SelectionChangedCause.keyboard);
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
      // TODO(justinmc): Should handle all actions from
      // TextSelectionGestureDetectorBuilder and from
      // _TextFieldSelectionGestureDetectorBuilder.
      // TODO(justinmc): Alternative idea: These intents should map to actions
      // that are named for what they do. The mapping is different depending on
      // the platform. I guess I'd have a bunch of properties above like
      // _androidTextEditingActionMap etc. But then, would each action just be
      // a single call to a RenderEditable method?
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
        ControlATextIntent: _controlATextAction,
        ControlArrowLeftTextIntent: _controlArrowLeftTextAction,
        ControlArrowRightTextIntent: _controlArrowRightTextAction,
        ControlCTextIntent: _controlCTextAction,
        ControlShiftArrowLeftTextIntent: _controlShiftArrowLeftTextAction,
        ControlShiftArrowRightTextIntent: _controlShiftArrowRightTextAction,
        EndTextIntent: _endTextAction,
        HomeTextIntent: _homeTextAction,
        MetaCTextIntent: _metaCTextAction,
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
        SingleTapUpTextIntent: _singleTapUpTextAction,
        ShiftHomeTextIntent: _shiftHomeTextAction,
        ShiftEndTextIntent: _shiftEndTextAction,
      },
      child: child,
    );
  }
}
