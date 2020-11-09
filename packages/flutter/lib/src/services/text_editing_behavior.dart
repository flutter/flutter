import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

class SingleTapUpTextIntent extends Intent {
  const SingleTapUpTextIntent({
    required this.details,
    required this.editableTextState,
    required this.renderEditable,
  });

  final TapUpDetails details;
  final EditableTextState editableTextState;
  final RenderEditable renderEditable;
}

class TapDownTextIntent extends Intent {
  const TapDownTextIntent({
    required this.details,
    required this.renderEditable,
  });

  final TapDownDetails details;
  final RenderEditable renderEditable;
}

// TODO(justinmc): Should handle all actions from
// TextSelectionGestureDetectorBuilder and from
// _TextFieldSelectionGestureDetectorBuilder.
// Rename and move file.
class TextEditingActionsMap {
  TextEditingActionsMap({
    required this.platform,
  });

  // TODO(justinmc): Can I just import foundation here to get this?
  final TargetPlatform platform;

  Map<Type, Action<Intent>>? _map;
  Map<Type, Action<Intent>> get map {
    _map ??= <Type, Action<Intent>>{
      SingleTapUpTextIntent: singleTapUpTextAction,
      TapDownTextIntent: tapDownTextAction,
    };
    return _map!;
  }

  CallbackAction<SingleTapUpTextIntent>? _singleTapUpTextAction;
  CallbackAction<SingleTapUpTextIntent> get singleTapUpTextAction {
    _singleTapUpTextAction ??= CallbackAction<SingleTapUpTextIntent>(
      onInvoke: (SingleTapUpTextIntent intent) {
        intent.editableTextState.hideToolbar();
        if (intent.editableTextState.widget.selectionEnabled) {
          switch (platform) {
            case TargetPlatform.iOS:
            case TargetPlatform.macOS:
              switch (intent.details.kind) {
                case PointerDeviceKind.mouse:
                case PointerDeviceKind.stylus:
                case PointerDeviceKind.invertedStylus:
                  // Precise devices should place the cursor at a precise position.
                  intent.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
                  break;
                case PointerDeviceKind.touch:
                case PointerDeviceKind.unknown:
                  // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
                  // of the word.
                  intent.renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
                  break;
              }
              break;
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
            case TargetPlatform.linux:
            case TargetPlatform.windows:
              intent.renderEditable.selectPosition(cause: SelectionChangedCause.tap);
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
    return _singleTapUpTextAction!;
  }

  /// Handler for [TextSelectionGestureDetector.onTapDown].
  ///
  /// By default, it forwards the tap to [RenderEditable.handleTapDown] and sets
  /// [shouldShowSelectionToolbar] to true if the tap was initiated by a finger or stylus.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onTapDown], which triggers this callback.
  CallbackAction<TapDownTextIntent>? _tapDownTextAction;
  CallbackAction<TapDownTextIntent> get tapDownTextAction {
    _tapDownTextAction ??= CallbackAction<TapDownTextIntent>(
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
    return _tapDownTextAction!;
  }
}
