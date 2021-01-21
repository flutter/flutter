// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, TextEditingAction;
import 'package:flutter/widgets.dart';

class AltArrowLeftTextIntent extends Intent {}
class AltArrowRightTextIntent extends Intent {}
class ArrowLeftTextIntent extends Intent {}
class ArrowRightTextIntent extends Intent {}
class ControlATextIntent extends Intent {}
class ControlArrowLeftTextIntent extends Intent {}
class ControlArrowRightTextIntent extends Intent {}
class ControlCTextIntent extends Intent {}
class MetaCTextIntent extends Intent {}
class ShiftArrowLeftTextIntent extends Intent {}
class ShiftArrowRightTextIntent extends Intent {}

class TapDownTextIntent extends Intent {
  const TapDownTextIntent({
    required this.details,
    required this.renderEditable,
  });

  final TapDownDetails details;
  final RenderEditable renderEditable;
}

// TODO(justinmc): Document.
/// The map of [Action]s that correspond to the default behavior for Flutter on
/// the current platform.
///
/// See also:
///
/// * [Actions], the widget that accepts a map like this.
class TextEditingActions extends StatelessWidget {
  TextEditingActions({
    Key? key,
    // TODO(justinmc): Is additionalActions a good way to do this?
    Map<Type, Action<Intent>>? additionalActions,
    required this.child,
  }) : this.additionalActions = additionalActions ?? Map<Type, Action<Intent>>(),
       super(key: key);

  final Widget child;

  final Map<Type, Action<Intent>> additionalActions;

  final CallbackAction<SingleTapUpTextIntent> _singleTapUpTextAction = CallbackAction<SingleTapUpTextIntent>(
    onInvoke: (SingleTapUpTextIntent intent) {
      print('justin TEB singleTapUp action invoked');
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
      // TODO(justinmc): State of keyboard visibility should be controllable here
      // too.
      //_state._requestKeyboard();

      // TODO(justinmc): Still need to handle calling of onTap.
      //if (_state.widget.onTap != null)
      //  _state.widget.onTap!();
    },
  );

  /// Handler for [TextSelectionGestureDetector.onTapDown].
  ///
  /// By default, it forwards the tap to [RenderEditable.handleTapDown] and sets
  /// [shouldShowSelectionToolbar] to true if the tap was initiated by a finger or stylus.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onTapDown], which triggers this callback.
  final CallbackAction<TapDownTextIntent> _tapDownTextAction = CallbackAction<TapDownTextIntent>(
    onInvoke: (TapDownTextIntent intent) {
      // TODO(justinmc): Should be no handling anything in renderEditable, it
      // should just receive commands to do specific things.
      intent.renderEditable.handleTapDown(intent.details);
      // The selection overlay should only be shown when the user is interacting
      // through a touch screen (via either a finger or a stylus). A mouse shouldn't
      // trigger the selection overlay.
      // For backwards-compatibility, we treat a null kind the same as touch.
      //final PointerDeviceKind? kind = intent.details.kind;
      // TODO(justinmc): What about _shouldShowSelectionToolbar?
      /*
      _shouldShowSelectionToolbar = kind == null
        || kind == PointerDeviceKind.touch
        || kind == PointerDeviceKind.stylus;
        */
    },
  );

  final TextEditingAction<AltArrowLeftTextIntent> _altArrowLeftTextAction = TextEditingAction<AltArrowLeftTextIntent>(
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

  final TextEditingAction<AltArrowRightTextIntent> _altArrowRightTextAction = TextEditingAction<AltArrowRightTextIntent>(
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

  final TextEditingAction<ArrowLeftTextIntent> _arrowLeftTextAction = TextEditingAction<ArrowLeftTextIntent>(
    onInvoke: (ArrowLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ArrowRightTextIntent> _arrowRightTextAction = TextEditingAction<ArrowRightTextIntent>(
    onInvoke: (ArrowRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.moveSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ControlCTextIntent> _controlCTextAction = TextEditingAction<ControlCTextIntent>(
    onInvoke: (ControlCTextIntent intent, EditableTextState editableTextState) {
      print('justin copy (with control, not command)');
    },
  );

  final TextEditingAction<ControlATextIntent> _controlATextAction = TextEditingAction<ControlATextIntent>(
    onInvoke: (ControlATextIntent intent, EditableTextState editableTextState) {
      // TODO(justinmc): Select all.
    },
  );

  final TextEditingAction<ControlArrowLeftTextIntent> _controlArrowLeftTextAction = TextEditingAction<ControlArrowLeftTextIntent>(
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

  final TextEditingAction<ControlArrowRightTextIntent> _controlArrowRightTextAction = TextEditingAction<ControlArrowRightTextIntent>(
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

  final TextEditingAction<MetaCTextIntent> _metaCTextAction = TextEditingAction<MetaCTextIntent>(
    onInvoke: (MetaCTextIntent intent, EditableTextState editableTextState) {
      // TODO(justinmc): This needs to be deduplicated with text_selection.dart.
      final TextSelectionDelegate delegate = editableTextState.renderEditable.textSelectionDelegate;
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

  final TextEditingAction<ShiftArrowLeftTextIntent> _shiftArrowLeftTextAction = TextEditingAction<ShiftArrowLeftTextIntent>(
    onInvoke: (ShiftArrowLeftTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionLeft(SelectionChangedCause.keyboard);
    },
  );

  final TextEditingAction<ShiftArrowRightTextIntent> _shiftArrowRightTextAction = TextEditingAction<ShiftArrowRightTextIntent>(
    onInvoke: (ShiftArrowRightTextIntent intent, EditableTextState editableTextState) {
      editableTextState.renderEditable.extendSelectionRight(SelectionChangedCause.keyboard);
    },
  );

  @override
  Widget build(BuildContext context) {
    return Actions(
      // TODO(justinmc): Should handle all actions from
      // TextSelectionGestureDetectorBuilder and from
      // _TextFieldSelectionGestureDetectorBuilder.
      actions: <Type, Action<Intent>>{
        ...additionalActions,
        AltArrowLeftTextIntent: _altArrowLeftTextAction,
        AltArrowRightTextIntent: _altArrowRightTextAction,
        ArrowLeftTextIntent: _arrowLeftTextAction,
        ArrowRightTextIntent: _arrowRightTextAction,
        ControlATextIntent: _controlATextAction,
        ControlArrowLeftTextIntent: _controlArrowLeftTextAction,
        ControlArrowRightTextIntent: _controlArrowRightTextAction,
        ControlCTextIntent: _controlCTextAction,
        MetaCTextIntent: _metaCTextAction,
        ShiftArrowLeftTextIntent: _shiftArrowLeftTextAction,
        ShiftArrowRightTextIntent: _shiftArrowRightTextAction,
        SingleTapUpTextIntent: _singleTapUpTextAction,
        TapDownTextIntent: _tapDownTextAction,
      },
      child: child,
    );
  }
}
