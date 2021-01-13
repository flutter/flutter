import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

// TODO(justinmc): Remove from widgets/text_selection.dart.
/// A duration that controls how often the drag selection update callback is
/// called.
const Duration _kDragSelectionUpdateThrottle = Duration(milliseconds: 50);

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

class DoubleTapDownTextIntent extends Intent {
  const DoubleTapDownTextIntent();
}

class DragSelectionEndTextIntent extends Intent {
  const DragSelectionEndTextIntent();
}

class DragSelectionStartTextIntent extends Intent {
  const DragSelectionStartTextIntent();
}

class DragSelectionUpdateTextIntent extends Intent {
  const DragSelectionUpdateTextIntent();
}

class ForcePressEndTextIntent extends Intent {
  const ForcePressEndTextIntent();
}

class ForcePressStartTextIntent extends Intent {
  const ForcePressStartTextIntent();
}

class SingleLongTapEndTextIntent extends Intent {
  const SingleLongTapEndTextIntent();
}

class SingleLongTapMoveUpdateTextIntent extends Intent {
  const SingleLongTapMoveUpdateTextIntent();
}

class SingleLongTapStartTextIntent extends Intent {
  const SingleLongTapStartTextIntent();
}

class SingleTapCancelTextIntent extends Intent {
  const SingleTapCancelTextIntent();
}

class SingleTapUpTextIntent extends Intent {
  const SingleTapUpTextIntent({
    required this.details,
    required this.editableTextState,
  });

  final TapUpDetails details;
  final EditableTextState editableTextState;
}

class TapDownTextIntent extends Intent {
  const TapDownTextIntent({
    required this.details,
    required this.renderEditable,
  });

  final TapDownDetails details;
  final RenderEditable renderEditable;
}

// TODO(justinmc): Instead of passing in editableTextState like this, should I
// create a hardcoded Intent type that has it?
// Or, should _editableTextState be public but protected?
/// The signature of a callback accepted by [TextEditingAction].
typedef OnInvokeTextEditingCallback<T extends Intent> = Object? Function(
  T intent,
  EditableTextState editableTextState,
);

/// An [Action] related to editing text.
///
/// If an [EditableText] is currently focused, the given [onInvoke] callback
/// will be called with the [EditableTextState]. If not, then [isEnabled] will
/// be false and [onInvoke] will not be called.
///
/// See also:
///
///  * [CallbackAction], which is a similar Action type but unrelated to text
///    editing.
class TextEditingAction<T extends Intent> extends Action<T> {
  /// A constructor for a [TextEditingAction].
  ///
  /// The [onInvoke] parameter must not be null.
  /// The [onInvoke] parameter is required.
  TextEditingAction({required this.onInvoke}) : assert(onInvoke != null);

  EditableTextState? get _editableTextState {
    // If an EditableText is not focused, then ignore this action.
    if (primaryFocus?.context?.widget is! EditableText) {
      return null;
    }
    final EditableText editableText = primaryFocus!.context!.widget as EditableText;
    // TODO(justinmc): I seem to need the EditableText to have a key for
    // this. Is there another way to get EditableTextState, or should I
    // force EditableText to have a key?
    if (editableText.key == null
        || (editableText.key! as GlobalKey).currentState == null) {
      return null;
    }
    return (editableText.key! as GlobalKey).currentState! as EditableTextState;
  }

  /// The callback to be called when invoked.
  ///
  /// If an EditableText is not focused, then isEnabled will be false, and this
  /// will not be invoked.
  ///
  /// Must not be null.
  @protected
  final OnInvokeTextEditingCallback<T> onInvoke;

  @override
  Object? invoke(covariant T intent) {
    // _editableTextState shouldn't be null because isEnabled will return false
    // and invoke shouldn't be called if so.
    assert(_editableTextState != null);
    return onInvoke(intent, _editableTextState!);
  }

  @override
  bool isEnabled(Intent intent) {
    return _editableTextState != null;
  }
}

// TODO(justinmc): Should handle all actions from
// TextSelectionGestureDetectorBuilder and from
// _TextFieldSelectionGestureDetectorBuilder.
// Rename and move file.
/// The map of [Action]s that correspond to the default behavior for Flutter on
/// the current platform.
///
/// See also:
///
/// * [Actions], the widget that accepts a map like this.
final Map<Type, Action<Intent>> textEditingActionsMap = <Type, Action<Intent>>{
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
};

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

// TODO(justinmc): Remove from widgets/text_selection.dart.
/// A gesture detector to respond to non-exclusive event chains for a text field.
///
/// An ordinary [GestureDetector] configured to handle events like tap and
/// double tap will only recognize one or the other. This widget detects both:
/// first the tap and then, if another tap down occurs within a time limit, the
/// double tap.
///
/// See also:
///
///  * [TextField], a Material text field which uses this gesture detector.
///  * [CupertinoTextField], a Cupertino text field which uses this gesture
///    detector.
class TextEditingGestureDetector extends StatefulWidget {
  /// Create a [TextEditingGestureDetector].
  ///
  /// The [child] parameter must not be null.
  const TextEditingGestureDetector({
    Key? key,
    required this.child,
    required this.editableTextKey,
  }) : assert(child != null),
       super(key: key);

  // TODO(justinmc): Think about encapsulation.
  final GlobalKey<EditableTextState> editableTextKey;

  /// Child below this widget.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _TextEditingGestureDetectorState();
}

class _TextEditingGestureDetectorState extends State<TextEditingGestureDetector> {
  // Counts down for a short duration after a previous tap. Null otherwise.
  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;
  // True if a second tap down of a double tap is detected. Used to discard
  // subsequent tap up / tap hold of the same tap.
  bool _isDoubleTap = false;

  EditableTextState get _editableTextState => widget.editableTextKey.currentState!;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _dragUpdateThrottleTimer?.cancel();
    super.dispose();
  }

  // The down handler is force-run on success of a single tap and optimistically
  // run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    Actions.invoke<TapDownTextIntent>(context, TapDownTextIntent(
      details: details,
      renderEditable: _editableTextState.renderEditable,
    ), nullOk: true);
    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things depending
    // on whether it's a single tap, the first tap of a double tap, the second
    // tap held down, a clean double tap etc.
    if (_doubleTapTimer != null && _isWithinDoubleTapTolerance(details.globalPosition)) {
      // If there was already a previous tap, the second down hold/tap is a
      // double tap down.
      Actions.invoke<DoubleTapDownTextIntent>(context, DoubleTapDownTextIntent(), nullOk: true);

      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      Actions.invoke<SingleTapUpTextIntent>(context, SingleTapUpTextIntent(
        details: details,
        editableTextState: _editableTextState,
      ), nullOk: true);
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }
    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    Actions.invoke<SingleTapCancelTextIntent>(context, SingleTapCancelTextIntent(), nullOk: true);
  }

  DragStartDetails? _lastDragStartDetails;
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;
    Actions.invoke<DragSelectionStartTextIntent>(context, DragSelectionStartTextIntent(), nullOk: true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _lastDragUpdateDetails = details;
    // Only schedule a new timer if there's no one pending.
    _dragUpdateThrottleTimer ??= Timer(_kDragSelectionUpdateThrottle, _handleDragUpdateThrottled);
  }

  /// Drag updates are being throttled to avoid excessive text layouts in text
  /// fields. The frequency of invocations is controlled by the constant
  /// [_kDragSelectionUpdateThrottle].
  ///
  /// Once the drag gesture ends, any pending drag update will be fired
  /// immediately. See [_handleDragEnd].
  void _handleDragUpdateThrottled() {
    assert(_lastDragStartDetails != null);
    assert(_lastDragUpdateDetails != null);
    Actions.invoke<DragSelectionUpdateTextIntent>(context, DragSelectionUpdateTextIntent(), nullOk: true);
    _dragUpdateThrottleTimer = null;
    _lastDragUpdateDetails = null;
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_lastDragStartDetails != null);
    if (_dragUpdateThrottleTimer != null) {
      // If there's already an update scheduled, trigger it immediately and
      // cancel the timer.
      _dragUpdateThrottleTimer!.cancel();
      _handleDragUpdateThrottled();
    }
    Actions.invoke<DragSelectionEndTextIntent>(context, DragSelectionEndTextIntent(), nullOk: true);
    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    Actions.invoke<ForcePressStartTextIntent>(context, ForcePressStartTextIntent(), nullOk: true);
  }

  void _forcePressEnded(ForcePressDetails details) {
    Actions.invoke<ForcePressEndTextIntent>(context, ForcePressEndTextIntent(), nullOk: true);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap) {
      Actions.invoke<SingleLongTapStartTextIntent>(context, SingleLongTapStartTextIntent(), nullOk: true);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap) {
      Actions.invoke<SingleLongTapMoveUpdateTextIntent>(context, SingleLongTapMoveUpdateTextIntent(), nullOk: true);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap) {
      Actions.invoke<SingleLongTapEndTextIntent>(context, SingleLongTapEndTextIntent(), nullOk: true);
    }
    _isDoubleTap = false;
  }

  void _doubleTapTimeout() {
    _doubleTapTimer = null;
    _lastTapOffset = null;
  }

  bool _isWithinDoubleTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};

    // Use _TransparentTapGestureRecognizer so that TextEditingGestureDetector
    // can receive the same tap events that a selection handle placed visually
    // on top of it also receives.
    gestures[_TransparentTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_TransparentTapGestureRecognizer>(
      () => _TransparentTapGestureRecognizer(debugOwner: this),
      (_TransparentTapGestureRecognizer instance) {
        instance
          ..onTapDown = _handleTapDown
          ..onTapUp = _handleTapUp
          ..onTapCancel = _handleTapCancel;
      },
    );

    gestures[LongPressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(debugOwner: this, kind: PointerDeviceKind.touch),
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _handleLongPressStart
          ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
          ..onLongPressEnd = _handleLongPressEnd;
      },
    );

    // TODO(mdebbar): Support dragging in any direction (for multiline text).
    // https://github.com/flutter/flutter/issues/28676
    gestures[HorizontalDragGestureRecognizer] = GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
      () => HorizontalDragGestureRecognizer(debugOwner: this, kind: PointerDeviceKind.mouse),
      (HorizontalDragGestureRecognizer instance) {
        instance
          // Text selection should start from the position of the first pointer
          // down event.
          ..dragStartBehavior = DragStartBehavior.down
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd;
      },
    );

    gestures[ForcePressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
      () => ForcePressGestureRecognizer(debugOwner: this),
      (ForcePressGestureRecognizer instance) {
        instance
          ..onStart = _forcePressStarted
          ..onEnd = _forcePressEnded;
      },
    );

    return RawGestureDetector(
      gestures: gestures,
      excludeFromSemantics: true,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

// TODO(justinmc): remove from widgets/text_selection.dart.
// A TapGestureRecognizer which allows other GestureRecognizers to win in the
// GestureArena. This means both _TransparentTapGestureRecognizer and other
// GestureRecognizers can handle the same event.
//
// This enables proper handling of events on both the selection handle and the
// underlying input, since there is significant overlap between the two given
// the handle's padded hit area.  For example, the selection handle needs to
// handle single taps on itself, but double taps need to be handled by the
// underlying input.
class _TransparentTapGestureRecognizer extends TapGestureRecognizer {
  _TransparentTapGestureRecognizer({
    Object? debugOwner,
  }) : super(debugOwner: debugOwner);

  @override
  void rejectGesture(int pointer) {
    // Accept new gestures that another recognizer has already won.
    // Specifically, this needs to accept taps on the text selection handle on
    // behalf of the text field in order to handle double tap to select. It must
    // not accept other gestures like longpresses and drags that end outside of
    // the text field.
    if (state == GestureRecognizerState.ready) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}
