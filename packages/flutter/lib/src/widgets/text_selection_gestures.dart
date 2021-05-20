// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'actions.dart';
import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text_editing_intents.dart';
import 'text_selection.dart';

class TextEditingGestures extends InheritedWidget {
  const TextEditingGestures({
    Key? key,
    this.gestures = const <Type, GestureRecognizerFactory>{},
    this.inherit = false,
    required Widget child,
  }) : super(key: key, child: child);

  TextEditingGestures.platformDefaults({
    Key? key,
    required Widget child,
  }) : this(key: key, gestures: _getPlatformDefaults, child: child);

  final Map<Type, GestureRecognizerFactory> gestures;
  final bool inherit;

  // context: The BuildContext that will be used as the new start point for
  // looking up gestures.
  // dependent: The first 'context'
  void _addInheritedGesturesToMap(Map<Type, GestureRecognizerFactory> map, BuildContext context, BuildContext dependent) {
    final InheritedElement? ancestor = context.getElementForInheritedWidgetOfExactType<TextEditingGestures>();
    if (!inherit || ancestor == null) {
      map.addAll(gestures);
      return;
    }

    // Does this work? Multiple dependencies with the same widget type?
    dependent.dependOnInheritedElement(ancestor);
    final TextEditingGestures ancestorWidget = ancestor.widget as TextEditingGestures;
    ancestorWidget._addInheritedGesturesToMap(map, ancestor, dependent);
    map.addAll(gestures);
  }

  static Map<Type, GestureRecognizerFactory>? maybeOf(BuildContext context) {
    final TextEditingGestures? widget = context.dependOnInheritedWidgetOfExactType<TextEditingGestures>();
    if (widget == null || !widget.inherit) {
      return widget?.gestures;
    }
    final Map<Type, GestureRecognizerFactory> map = <Type, GestureRecognizerFactory>{};
    widget._addInheritedGesturesToMap(map, context, context);
    return map;
  }

  static Map<Type, GestureRecognizerFactory> _getPlatformDefaults {
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TextEditingTapGestureRecognizer>(
        () => TextEditingTapGestureRecognizer(maxConsecutiveTaps: 2, notifyStatusChanged: notifyStatusChanged),
        (TextEditingTapGestureRecognizer instance) {},
      ),
      LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(),
        (LongPressGestureRecognizer instance) =>
      ),
      HorizontalDragGestureRecognizer: _GestureRecognizerFactoryWrapper<HorizontalDragGestureRecognizer>(dragGestureRecognizer),
      ForcePressGestureRecognizer: _GestureRecognizerFactoryWrapper<ForcePressGestureRecognizer>(forcePressGestureRecognizer),
    };
  }

  @override
  bool updateShouldNotify(TextEditingGestures oldWidget) {
    return oldWidget.gestures != gestures
        || oldWidget.inherit != inherit;
  }
}

// ---------- Text Editing Gesture Recognizers ----------

class TapTextGestureStatus {
  TapTextGestureStatus._(this._tapDownDetails);

  int get tapDownCount => _tapDownCount;
  int _tapDownCount = 1;

  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  TapDownDetails get tapDownDetails => _tapDownDetails;
  TapDownDetails _tapDownDetails;

  TapUpDetails? get tapUpDetails => _tapUpDetails;
  TapUpDetails? _tapUpDetails;
}

class SecondaryTapTextGestureStatus {
  SecondaryTapTextGestureStatus._(this.tapDownDetails);

  bool get isRecognized => _isRecognized;
  bool _isRecognized = false;

  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  final TapDownDetails tapDownDetails;
}

class TextEditingTapGestureRecognizer extends GestureRecognizer {
  TextEditingTapGestureRecognizer({
    Object? debugOwner,
    required this.maxConsecutiveTaps,
    required VoidCallback notifyStatusChanged,
  }) : assert(maxConsecutiveTaps > 0),
       _notifyStatusChanged = notifyStatusChanged,
       super(debugOwner: debugOwner);

  late final TapGestureRecognizer _singleTapRecognizer = TapGestureRecognizer(debugOwner: this)
    ..onTapDown = _onTapDown
    ..onTapUp = _onTapUp
    ..onTapCancel = _onTapCancel;

  final int maxConsecutiveTaps;

  TapTextGestureStatus? get tapStatus => _tapStatus;
  TapTextGestureStatus? _tapStatus;

  SecondaryTapTextGestureStatus? get secondaryTapStatus => _secondaryTapStatus;
  SecondaryTapTextGestureStatus? _secondaryTapStatus;

  int get consecutiveTapDownCount => _consecutiveTapDownCount;
  int _consecutiveTapDownCount = 0;

  TapDownDetails? get tapDownDetails => _tapDownDetails;
  TapDownDetails? _tapDownDetails;

  TapUpDetails? get tapUpDetails {
    assert(_tapUpDetails == null || _tapDownDetails != null);
    assert(_tapUpDetails == null || _consecutiveTapDownCount > 0);
    return _tapUpDetails;
  }
  TapUpDetails? _tapUpDetails;

  bool get isTapCancelled => _isTapCancelled;
  bool _isTapCancelled = false;

  // Counts down for a short duration after a previous tap up event. If the
  // timer expires the consecutiveTapDownCount resets.
  Timer? _tapSequenceTimer;
  // The tap count needs to reset next time it increases.
  bool _resetTapDownCount = false;

  void _onTapDown(TapDownDetails details) {
    assert(!isTapCancelled);
    final TapUpDetails? previousTapUp = tapUpDetails;
    assert((_tapSequenceTimer == null) == (_consecutiveTapDownCount == 0));
    assert((previousTapUp == null) == (_consecutiveTapDownCount == 0));
    assert(_consecutiveTapDownCount < maxConsecutiveTaps);

    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;

    final bool isConsecutiveTap = !_resetTapDownCount
                               && previousTapUp != null
                               && previousTapUp.kind == details.kind
                               // Uses global position so that if a text field
                               // relocates the tap down misses.
                               && (previousTapUp.globalPosition - details.globalPosition).distance <= kDoubleTapSlop;

    _resetTapDownCount = false;
    // Update public status.
    _consecutiveTapDownCount = isConsecutiveTap ? _consecutiveTapDownCount + 1 : 1;
    _tapDownDetails = details;
    _tapUpDetails = null;

    _notifyStatusChanged();
  }

  void _onTapUp(TapUpDetails details) {
    assert(_tapSequenceTimer == null);
    assert(!isTapCancelled);
    assert(tapUpDetails == null);
    final TapDownDetails? previousDownEvent = tapDownDetails;
    if (previousDownEvent == null) {
      assert(false, 'previous down event must not be null');
      return;
    }

    _tapUpDetails = details;
    final bool shouldEndConsecutiveTaps = consecutiveTapDownCount >= maxConsecutiveTaps;
    if (shouldEndConsecutiveTaps) {
      _scheduleTapCountReset();
    } else {
      _tapSequenceTimer = Timer(kDoubleTapTimeout, _scheduleTapCountReset);
    }
    _notifyStatusChanged();
  }

  void _onTapCancel() {
    assert(_tapSequenceTimer == null);
    assert(!isTapCancelled);
    assert(tapUpDetails == null);
    final TapDownDetails? previousDownEvent = tapDownDetails;
    if (previousDownEvent == null) {
      assert(false, 'previous down event must not be null');
      return;
    }
    _isTapCancelled = true;

    _notifyStatusChanged();
    _scheduleTapCountReset();
  }

  void _scheduleTapCountReset() {
    assert(_tapSequenceTimer == null);
    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;
    _resetTapDownCount = true;
  }

  final VoidCallback _notifyStatusChanged;

  @override
  void acceptGesture(int pointer) {
    _singleTapRecognizer.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _singleTapRecognizer.rejectGesture(pointer);
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) => _singleTapRecognizer.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _singleTapRecognizer.addAllowedPointer(event);
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    _singleTapRecognizer.handleNonAllowedPointer(event);
    // Any new pointer events in the region of interest break the streak.
    _resetTapDownCount = true;
  }

  @override
  String get debugDescription => 'consecutive taps on editable text';
}

class LongPressTextGestureStatus {
  LongPressTextGestureStatus._(this.longPressStartDetails);

  final LongPressStartDetails longPressStartDetails;

  LongPressMoveUpdateDetails? get longPressMoveDetails => _longPressMoveDetails;
  LongPressMoveUpdateDetails? _longPressMoveDetails;

  LongPressEndDetails? get longPressEndDetails => _longPressEndDetails;
  LongPressEndDetails? _longPressEndDetails;
}

class DragTextGestureStatus {
  DragTextGestureStatus._(this.dragStartDetails);

  final DragStartDetails dragStartDetails;
  DragUpdateDetails? dragUpdateDetails;
  DragEndDetails? dragEndDetails;
}

class ForcePressTextGestureStatus {
  ForcePressTextGestureStatus._(this.forcePressStartDetails);

  final ForcePressDetails forcePressStartDetails;
  ForcePressDetails? forcePressEndDetails;
}

class _GestureRecognizerFactoryWrapper<T extends GestureRecognizer> implements GestureRecognizerFactory<T> {
  const _GestureRecognizerFactoryWrapper(this.gestureRecognizer);
  final T gestureRecognizer;

  @override
  T constructor() => gestureRecognizer;

  @override
  void initializer(T instance) { }
}

// ---------- Current Defaults ----------


class TextEditingGestureBuilder extends StatefulWidget {
  const TextEditingGestureBuilder({
    Key? key,
    required this.child,
    required this.delegate,
    required this.maxConsecutiveTaps,
    this.behavior,
  }) : super(key: key);

  final Widget child;
  final TextSelectionGestureDetectorBuilderDelegate delegate;
  final int maxConsecutiveTaps;
  final HitTestBehavior? behavior;

  @override
  State<TextEditingGestureBuilder> createState() => _TextEditingGestureBuilderState();
}

class _TextEditingGestureBuilderState extends State<TextEditingGestureBuilder> {
  @override
  void didUpdateWidget(TextEditingGestureBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle maxConsecutiveTaps.
  }

  // ---------- Tap Gesture Handling ----------

  late final TapGestureRecognizer tapGestureRecognizer = TapGestureRecognizer(debugOwner: this)
    ..onTapDown = _handleTapDown
    ..onTapUp = _handleTapUp
    ..onTapCancel = _handleTapCancel
    ..onSecondaryTap = _handleSecondaryTap
    ..onSecondaryTapDown = _handleSecondaryTapDown
    ..onSecondaryTapCancel = _handleSecondaryTapCancel;

  TapTextGestureIntent? currentTapIntent;

  // The down handler is force-run on success of a single tap and optimistically
  // run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    // When a tap gesture is cancelled, we should set currentTapIntent to null.
    assert(!(currentTapIntent?.gestureStatus.isCancelled ?? false));
    final TapTextGestureIntent? tapIntent = currentTapIntent;
    final bool isConsecutiveTap = tapIntent != null
        && details.kind == tapIntent.gestureStatus.tapDownDetails.kind
        && (details.globalPosition - tapIntent.gestureStatus.tapDownDetails.globalPosition).distance <= kDoubleTapSlop;

    final TapTextGestureStatus tapGestureStatus;

    if (tapIntent != null && isConsecutiveTap) {
      assert(tapIntent.gestureStatus.tapDownCount >= 0);
      assert(tapIntent.gestureStatus.tapDownCount < widget.maxConsecutiveTaps);

      tapGestureStatus = tapIntent.gestureStatus
        .._tapDownCount += 1
        .._tapDownDetails = details
        .._tapUpDetails = null;
    } else {
      tapGestureStatus = TapTextGestureStatus._(details);
    }
    final TapTextGestureIntent intent = TapTextGestureIntent(
      gestureStatus: tapGestureStatus,
      maxTapCount: widget.maxConsecutiveTaps,
      gestureDelegate: widget.delegate,
    );
    currentTapIntent = intent;

    assert(tapGestureStatus.tapDownCount >= 1);
    assert((_tapSequenceTimer == null) == (tapGestureStatus.tapDownCount == 1));

    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things depending
    // on whether it's a single tap, the first tap of a double tap, the second
    // tap held down, a clean double tap etc.

    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;

    // Fire off the updated intent.
    _notifyGestureStatusChanged(intent);
  }

  void _handleTapUp(TapUpDetails details) {
    assert(_tapSequenceTimer == null);
    final TapTextGestureIntent? tapIntent = currentTapIntent;
    if (tapIntent == null) {
      assert(false, 'tap intent cannot be null');
      return;
    }

    assert(!tapIntent.gestureStatus.isCancelled);
    assert(tapIntent.gestureStatus.tapUpDetails == null);
    tapIntent.gestureStatus._tapUpDetails = details;

    if (tapIntent.gestureStatus.tapDownCount < widget.maxConsecutiveTaps) {
      _tapSequenceTimer = Timer(kDoubleTapTimeout, _resetStatus);
    }

    _notifyGestureStatusChanged(tapIntent);

    final bool shouldEndTapGesture = tapIntent.gestureStatus.tapDownCount >= widget.maxConsecutiveTaps;
    if (shouldEndTapGesture) {
      _resetStatus();
    }
  }

  void _handleTapCancel() {
    assert(_tapSequenceTimer == null);
    final TapTextGestureIntent? tapIntent = currentTapIntent;
    if (tapIntent == null) {
      assert(false, 'tap intent cannot be null');
      return;
    }

    assert(!tapIntent.gestureStatus.isCancelled);
    assert(tapIntent.gestureStatus.tapUpDetails == null);
    tapIntent.gestureStatus._isCancelled = true;
    _notifyGestureStatusChanged(tapIntent);
    _resetStatus();
  }

  void _resetStatus() {
    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;
    currentTapIntent = null;
  }

  // ---------- Secondary Tap Gesture Handling ----------

  SecondaryTapTextGestureIntent? currentSecondaryTapIntent;

  void _handleSecondaryTapDown(TapDownDetails tapDownDetails) {
    // This is an one-sequence gesture.
    assert(currentSecondaryTapIntent == null);
    final SecondaryTapTextGestureIntent intent = SecondaryTapTextGestureIntent(
      gestureStatus: SecondaryTapTextGestureStatus._(tapDownDetails),
      gestureDelegate: widget.delegate,
    );
    currentSecondaryTapIntent = intent;
    _notifyGestureStatusChanged(intent);
  }

  void _handleSecondaryTap() {
    final SecondaryTapTextGestureIntent? secondaryTapIntent = currentSecondaryTapIntent;
    if (secondaryTapIntent == null) {
      assert(false, 'secondary tap intent cannot be null');
      return;
    }
    assert(!secondaryTapIntent.gestureStatus.isCancelled);
    assert(!secondaryTapIntent.gestureStatus.isRecognized);

    secondaryTapIntent.gestureStatus._isRecognized = true;
    _notifyGestureStatusChanged(secondaryTapIntent);
    currentSecondaryTapIntent = null;
  }

  void _handleSecondaryTapCancel() {
    final SecondaryTapTextGestureIntent? secondaryTapIntent = currentSecondaryTapIntent;
    if (secondaryTapIntent == null) {
      assert(false, 'secondary tap intent cannot be null');
      return;
    }
    assert(!secondaryTapIntent.gestureStatus.isCancelled);
    assert(!secondaryTapIntent.gestureStatus.isRecognized);

    secondaryTapIntent.gestureStatus._isCancelled = true;
    _notifyGestureStatusChanged(secondaryTapIntent);
    currentSecondaryTapIntent = null;
  }

  // ---------- Long Press Gesture Handling ----------

  late final LongPressGestureRecognizer longPressGestureRecognizer = LongPressGestureRecognizer(debugOwner: this)
    ..onLongPressStart = _handleLongPressStart
    ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
    ..onLongPressEnd = _handleLongPressEnd;

  LongPressTextGestureIntent? currentLongPressIntent;

  void _handleLongPressStart(LongPressStartDetails details) {
    assert(currentLongPressIntent == null);
    final LongPressTextGestureIntent intent = LongPressTextGestureIntent(
      gestureDelegate: widget.delegate,
      gestureStatus: LongPressTextGestureStatus._(details),
    );
    currentLongPressIntent = intent;
    _notifyGestureStatusChanged(intent);
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final LongPressTextGestureIntent? currentLongPressIntent = this.currentLongPressIntent;
    if (currentLongPressIntent == null) {
      assert(false, 'long press intent cannot be null');
      return;
    }
    assert(currentLongPressIntent.gestureStatus.longPressEndDetails == null);
    currentLongPressIntent.gestureStatus._longPressMoveDetails = details;
    _notifyGestureStatusChanged(currentLongPressIntent);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    final LongPressTextGestureIntent? currentLongPressIntent = this.currentLongPressIntent;
    if (currentLongPressIntent == null) {
      assert(false, 'long press intent cannot be null');
      return;
    }
    assert(currentLongPressIntent.gestureStatus.longPressEndDetails == null);
    currentLongPressIntent.gestureStatus._longPressEndDetails = details;
    _notifyGestureStatusChanged(currentLongPressIntent);
    this.currentLongPressIntent = null;
  }

  // ---------- Drag Gesture Handling ----------

  late final HorizontalDragGestureRecognizer dragGestureRecognizer = HorizontalDragGestureRecognizer(debugOwner: this)
    ..onStart = _handleDragStart
    ..onUpdate = _handleDragUpdate
    ..onEnd = _handleDragEnd;

  DragTextGestureIntent? currentDragIntent;

  void _handleDragStart(DragStartDetails details) {
    assert(currentDragIntent == null);
    final DragTextGestureIntent intent = DragTextGestureIntent(
      gestureDelegate: widget.delegate,
      gestureStatus: DragTextGestureStatus._(details),
    );
    currentDragIntent = intent;
    _notifyGestureStatusChanged<DragTextGestureIntent>(intent);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final DragTextGestureIntent? currentDragIntent = this.currentDragIntent;
    if (currentDragIntent == null) {
      assert(false, 'drag intent cannot be null');
      return;
    }
    assert(currentDragIntent.gestureStatus.dragEndDetails == null);

    currentDragIntent.gestureStatus.dragUpdateDetails = details;
    _notifyGestureStatusChanged(currentDragIntent);
  }

  /// Drag updates are being throttled to avoid excessive text layouts in text
  /// fields. The frequency of invocations is controlled by the constant
  /// [_kDragSelectionUpdateThrottle].
  ///
  /// Once the drag gesture ends, any pending drag update will be fired
  /// immediately. See [_handleDragEnd].
  // void _handleDragUpdateThrottled() {
  //   _dragUpdateThrottleTimer = null;
  // }

  void _handleDragEnd(DragEndDetails details) {
    final DragTextGestureIntent? currentDragIntent = this.currentDragIntent;
    if (currentDragIntent == null) {
      assert(false, 'drag intent cannot be null');
      return;
    }
    assert(currentDragIntent.gestureStatus.dragEndDetails == null);
    currentDragIntent.gestureStatus.dragEndDetails = details;
    _notifyGestureStatusChanged(currentDragIntent);
    this.currentDragIntent = null;
  }

  // ---------- Force Press Gesture Handling ----------

  late final ForcePressGestureRecognizer forcePressGestureRecognizer = ForcePressGestureRecognizer(debugOwner: this)
    ..onStart = _handleForcePressStart
    ..onEnd = _handleForcePressEnd;

  ForcePressTextGestureIntent? currentForcePressTextGestureIntent;

  void _handleForcePressStart(ForcePressDetails details) {
    assert(currentForcePressTextGestureIntent == null);
    final ForcePressTextGestureIntent intent = ForcePressTextGestureIntent(
      gestureStatus: ForcePressTextGestureStatus._(details),
      gestureDelegate: widget.delegate,
    );
    currentForcePressTextGestureIntent = intent;
    _notifyGestureStatusChanged(intent);
  }

  void _handleForcePressEnd(ForcePressDetails details) {
    final ForcePressTextGestureIntent? currentForcePressTextGestureIntent = this.currentForcePressTextGestureIntent;
    if (currentForcePressTextGestureIntent == null) {
      assert(false, 'force press intent cannot be null');
      return;
    }
    assert(currentForcePressTextGestureIntent.gestureStatus.forcePressEndDetails == null);
    currentForcePressTextGestureIntent.gestureStatus.forcePressEndDetails = details;
    _notifyGestureStatusChanged(currentForcePressTextGestureIntent);
    this.currentForcePressTextGestureIntent = null;
  }

  void _notifyGestureStatusChanged<T extends Intent>(T intent) {
    Actions.maybeInvoke<T>(context, intent);
  }

  late final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{
    TapGestureRecognizer: _GestureRecognizerFactoryWrapper<TapGestureRecognizer>(tapGestureRecognizer),
    LongPressGestureRecognizer: _GestureRecognizerFactoryWrapper<LongPressGestureRecognizer>(longPressGestureRecognizer),
    HorizontalDragGestureRecognizer: _GestureRecognizerFactoryWrapper<HorizontalDragGestureRecognizer>(dragGestureRecognizer),
    ForcePressGestureRecognizer: _GestureRecognizerFactoryWrapper<ForcePressGestureRecognizer>(forcePressGestureRecognizer),
  };

  @override
  void dispose() {
    _tapSequenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      child: widget.child,
      behavior: widget.behavior,
      gestures: gestures,
    );
  }
}
