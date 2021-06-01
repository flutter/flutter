// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'actions.dart';
import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text_editing_intents.dart';

typedef ContextGestureRecognizerFactoryConstructor<T> = T Function(BuildContext);
typedef ContextGestureRecognizerFactoryInitializer<T> = void Function(T, BuildContext);

@optionalTypeArgs
abstract class ContextGestureRecognizerFactory<T extends GestureRecognizer> {
  const ContextGestureRecognizerFactory();

  const factory ContextGestureRecognizerFactory.withFunctions({
    required ContextGestureRecognizerFactoryConstructor<T> constructor,
    ContextGestureRecognizerFactoryInitializer<T>? initializer,
  }) = _ContextGestureRecognizerFactoryWithFunctions<T>;

  T construct(BuildContext context);

  void initialize(T instance, BuildContext context);

  bool _debugAssertTypeMatches(Type type) {
    assert(type == T, 'GestureRecognizerFactory of type $T was used where type $type was specified.');
    return true;
  }
}

class _ContextGestureRecognizerFactoryWithFunctions<T extends GestureRecognizer> extends ContextGestureRecognizerFactory<T> {
  const _ContextGestureRecognizerFactoryWithFunctions({
    required this.constructor,
    this.initializer,
  });

  final ContextGestureRecognizerFactoryConstructor<T> constructor;
  final ContextGestureRecognizerFactoryInitializer<T>? initializer;

  @override
  T construct(BuildContext context) => constructor(context);

  @override
  void initialize(T instance, BuildContext context) {
    initializer?.call(instance, context);
  }
}

class _InheritedTextEditingGestures extends InheritedWidget {
  const _InheritedTextEditingGestures({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  final _TextEditingGesturesState state;

  @override
  bool updateShouldNotify(_InheritedTextEditingGestures oldWidget) => oldWidget.state != state;
}

class TextEditingGestures extends StatefulWidget {
  const TextEditingGestures({
    Key? key,
    this.gestures = const <Type, ContextGestureRecognizerFactory>{},
    this.inherit = false,
    required this.child,
  }) : super(key: key);

  TextEditingGestures.platformDefaults({
    Key? key,
    required Widget child,
  }) : this(key: key, gestures: _getPlatformDefaults(), child: child);

  final Map<Type, ContextGestureRecognizerFactory> gestures;
  final bool inherit;
  final Widget child;

  void _addInheritedGesturesToMap(Map<Type, ContextGestureRecognizerFactory> map, BuildContext context) {
    if (!inherit) {
      map.addAll(gestures);
      return;
    }

    final _InheritedTextEditingGestures? inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedTextEditingGestures>();
    if (inheritedWidget == null) {
      map.addAll(gestures);
      return;
    }

    // This probably doesn't work. Multiple dependencies with the same widget type?
    inheritedWidget.state.widget._addInheritedGesturesToMap(map, inheritedWidget.state.context);
    map.addAll(gestures);
  }

  static Map<Type, ContextGestureRecognizerFactory>? maybeOf(BuildContext context) {
    final _InheritedTextEditingGestures? widget = context.dependOnInheritedWidgetOfExactType<_InheritedTextEditingGestures>();
    if (widget == null || !widget.state.widget.inherit) {
      return widget?.state.widget.gestures;
    }
    final Map<Type, ContextGestureRecognizerFactory> map = <Type, ContextGestureRecognizerFactory>{};
    widget.state.widget._addInheritedGesturesToMap(map, context);
    return map;
  }

  // TODO(LongCatIsLooong): Document provenance for each platform device kind.
  static final ContextGestureRecognizerFactory<LongPressGestureRecognizer> longPressRecognizer = ContextGestureRecognizerFactory<LongPressGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => LongPressGestureRecognizer(debugOwner: context),
    initializer: (LongPressGestureRecognizer recognizer, BuildContext context) {
      recognizer
        ..onLongPressStart = (LongPressStartDetails details) {
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              textBoundaryType: TextBoundary.word,
              cause: SelectionChangedCause.longPress,
            ),
          );
          Feedback.forLongPress(context);
          Actions.maybeInvoke(context, const SelectionHandleControlIntent(
            // TODO() stop faking this.
            deviceKind: PointerDeviceKind.touch,
            cause: SelectionChangedCause.longPress,
          ));
        }
        ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
          Actions.invoke(
            context,
            ExtendSelectionToPointIntent(
              toPosition: details.globalPosition,
              textBoundaryType: TextBoundary.word,
              cause: SelectionChangedCause.longPress,
            ),
          );
        }
        ..onLongPressEnd = (LongPressEndDetails details) {
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.show);
        };
    },
  );

  static final ContextGestureRecognizerFactory<LongPressGestureRecognizer> iOSMacOSlongPressRecognizer = ContextGestureRecognizerFactory<LongPressGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => LongPressGestureRecognizer(debugOwner: context),
    initializer: (LongPressGestureRecognizer recognizer, BuildContext context) {
      recognizer
        ..onLongPressStart = (LongPressStartDetails details) {
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              cause: SelectionChangedCause.longPress,
            ),
          );
        }
        ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              cause: SelectionChangedCause.longPress,
            ),
          );
        }
        ..onLongPressEnd = (LongPressEndDetails details) {
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.show);
        };
    },
  );

  static final ContextGestureRecognizerFactory<HorizontalDragGestureRecognizer> horizontalDragRecognizer = ContextGestureRecognizerFactory<HorizontalDragGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => HorizontalDragGestureRecognizer(debugOwner: context),
    initializer: (HorizontalDragGestureRecognizer recognizer, BuildContext context) {
      recognizer
        ..onStart = (DragStartDetails details) {
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              cause: SelectionChangedCause.drag,
            ),
          );
          Actions.maybeInvoke(context, SelectionHandleControlIntent(
            deviceKind: details.kind,
            cause: SelectionChangedCause.longPress,
          ));
        }
        ..onUpdate = (DragUpdateDetails details) {
          Actions.invoke(
            context,
            ExtendSelectionToPointIntent(
              toPosition: details.globalPosition,
              cause: SelectionChangedCause.drag,
            ),
          );
        };
    },
  );

  static final ContextGestureRecognizerFactory<TextEditingTapGestureRecognizer> tapRecognizer =  ContextGestureRecognizerFactory<TextEditingTapGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => TextEditingTapGestureRecognizer(debugOwner: context),
    initializer: (TextEditingTapGestureRecognizer recognizer, BuildContext context) {
      recognizer
        ..onTapDown = (TapDownDetails details, int tapDownCount) {
          // Only handle double taps here.
          if (tapDownCount % 2 != 0) {
            return;
          }
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              textBoundaryType: TextBoundary.word,
              cause: SelectionChangedCause.doubleTap,
            ),
          );
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.show);
          Actions.maybeInvoke(context, SelectionHandleControlIntent(
            deviceKind: details.kind,
            cause: SelectionChangedCause.doubleTap,
          ));
        }
        ..onTapUp = (TapUpDetails details, int tapDownCount) {
          if (tapDownCount %2 != 1) {
            return;
          }
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.hide);
          Actions.invoke(context, SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              cause: SelectionChangedCause.tap,
            ),
          );
          Actions.maybeInvoke(context, SelectionHandleControlIntent(
            deviceKind: details.kind,
            cause: SelectionChangedCause.tap,
          ));
          Actions.maybeInvoke(context, KeyboardControlIntent.showKeyboard);
          Actions.maybeInvoke(context, const InvokeTextEditingComponentOnTapCallbackIntent());
        };
    },
  );

  static final ContextGestureRecognizerFactory<TextEditingTapGestureRecognizer> iOSMacOStapRecognizer =  ContextGestureRecognizerFactory<TextEditingTapGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => TextEditingTapGestureRecognizer(debugOwner: context),
    initializer: (TextEditingTapGestureRecognizer recognizer, BuildContext context) {
      recognizer
        ..onTapDown = (TapDownDetails details, int tapDownCount) {
          if (tapDownCount % 2 != 0) {
            return;
          }
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              textBoundaryType: TextBoundary.word,
              cause: SelectionChangedCause.doubleTap,
            ),
          );
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.show);
          Actions.maybeInvoke(context, SelectionHandleControlIntent(
            deviceKind: details.kind,
            cause: SelectionChangedCause.doubleTap,
          ));
        }
        ..onTapUp = (TapUpDetails details, int tapDownCount) {
          if (tapDownCount % 2 != 1) {
            return;
          }
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.hide);
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              Actions.invoke(context, SelectTextAtPositionIntent(
                  fromPosition: details.globalPosition,
                  cause: SelectionChangedCause.tap,
                ),
              );
              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              Actions.invoke(context, SelectWordEdgeIntent(
                globalPosition: details.globalPosition,
                cause: SelectionChangedCause.tap,
              ));
              break;
          }
          Actions.maybeInvoke(context, SelectionHandleControlIntent(
            deviceKind: details.kind,
            cause: SelectionChangedCause.tap,
          ));
          Actions.maybeInvoke(context, KeyboardControlIntent.showKeyboard);
          Actions.maybeInvoke(context, const InvokeTextEditingComponentOnTapCallbackIntent());
        };

    },
  );

  // Handling Right-Click.
  static final ContextGestureRecognizerFactory<TapGestureRecognizer> secondaryTapRecognizer =  ContextGestureRecognizerFactory<TapGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => TapGestureRecognizer(debugOwner: context),
    initializer: (TapGestureRecognizer recognizer, BuildContext context) {
      recognizer.onSecondaryTapUp = (TapUpDetails details) {
        Actions.invoke(
          context,
          SelectTextAtPositionIntent(
            fromPosition: details.globalPosition,
            textBoundaryType: TextBoundary.word,
            cause: SelectionChangedCause.tap,
          ),
        );
        Actions.maybeInvoke(context, SelectionHandleControlIntent(
          deviceKind: details.kind,
          cause: SelectionChangedCause.tap,
        ));
        Actions.maybeInvoke(context, SelectionToolbarControlIntent.showAt(location: details.globalPosition));
      };
    }
  );

  static final ContextGestureRecognizerFactory<ForcePressGestureRecognizer> forcePressRecognizer = ContextGestureRecognizerFactory<ForcePressGestureRecognizer>.withFunctions(
    constructor: (BuildContext context) => ForcePressGestureRecognizer(debugOwner: context),
    initializer: (ForcePressGestureRecognizer recognizer, BuildContext context) {
      recognizer
        .onStart = (ForcePressDetails details) {
          Actions.invoke(
            context,
            SelectTextAtPositionIntent(
              fromPosition: details.globalPosition,
              textBoundaryType: TextBoundary.word,
              cause: SelectionChangedCause.forcePress,
            ),
          );
          Actions.maybeInvoke(context, const SelectionHandleControlIntent(
            // TODO(): stop faking this.
            deviceKind: PointerDeviceKind.touch,
            cause: SelectionChangedCause.forcePress,
          ));
          Actions.maybeInvoke(context, SelectionToolbarControlIntent.show);
        };
    },
  );

  static Map<Type, ContextGestureRecognizerFactory> _getPlatformDefaults() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return <Type, ContextGestureRecognizerFactory>{
          LongPressGestureRecognizer: iOSMacOSlongPressRecognizer,
          HorizontalDragGestureRecognizer: horizontalDragRecognizer,
          TextEditingTapGestureRecognizer: iOSMacOStapRecognizer,
          TapGestureRecognizer: secondaryTapRecognizer,
          ForcePressGestureRecognizer: forcePressRecognizer,
        };
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return <Type, ContextGestureRecognizerFactory>{
          LongPressGestureRecognizer: longPressRecognizer,
          HorizontalDragGestureRecognizer: horizontalDragRecognizer,
          TextEditingTapGestureRecognizer: tapRecognizer,
          TapGestureRecognizer: secondaryTapRecognizer,
          ForcePressGestureRecognizer: forcePressRecognizer,
        };
    }
  }

  @override
  State<StatefulWidget> createState() => _TextEditingGesturesState();
}

class _TextEditingGesturesState extends State<TextEditingGestures> {
  @override
  Widget build(BuildContext context) {
    return _InheritedTextEditingGestures(
      child: widget.child,
      state: this,
    );
  }
}

// ---------- Text Editing Gesture Recognizers ----------

class _TapTextGestureStatus {
  _TapTextGestureStatus._(this._tapDownDetails);

  int get tapDownCount => _tapDownCount;
  int _tapDownCount = 1;

  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  TapDownDetails get tapDownDetails => _tapDownDetails;
  TapDownDetails _tapDownDetails;

  TapUpDetails? get tapUpDetails => _tapUpDetails;
  TapUpDetails? _tapUpDetails;
}

typedef GestureConsecutiveTapDownCallback = void Function(TapDownDetails details, int tapDownCount);
typedef GestureConsecutiveTapUpCallback = void Function(TapUpDetails details, int tapDownCount);
typedef GestureConsecutiveTapCallback = void Function(TapDownDetails tapDownDetails, TapUpDetails tapUpDetails, int tapDownCount);
typedef GestureConsecutiveTapCancelCallback = void Function(int tapDownCount);

class TextEditingTapGestureRecognizer extends BaseTapGestureRecognizer {
  TextEditingTapGestureRecognizer({
    Object? debugOwner,
  }) : super(debugOwner: debugOwner);

  _TapTextGestureStatus? _tapStatus;

  // Counts down for a short duration after a previous tap up event. If the
  // timer expires the consecutiveTapDownCount resets.
  Timer? _tapSequenceTimer;

  /// A pointer has contacted the screen at a particular location with a primary
  /// button, which might be the start of a tap.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// If this recognizer doesn't win the arena, [onTapCancel] is called next.
  /// Otherwise, [onTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
  ///  * [onTertiaryTapDown], a similar callback but for a tertiary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTapDown], which exposes this callback.
  GestureConsecutiveTapDownCallback? onTapDown;

  /// A pointer has stopped contacting the screen at a particular location,
  /// which is recognized as a tap of a primary button.
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it
  /// or has previously won, immediately followed by [onTap].
  ///
  /// If this recognizer doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [onTertiaryTapUp], a similar callback but for a tertiary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTapUp], which exposes this callback.
  GestureConsecutiveTapUpCallback? onTapUp;

  /// A pointer has stopped contacting the screen, which is recognized as a tap
  /// of a primary button.
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it
  /// or has previously won, immediately following [onTapUp].
  ///
  /// If this recognizer doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTap], a similar callback but for a secondary button.
  ///  * [onTapUp], which has the same timing but with details.
  ///  * [GestureDetector.onTap], which exposes this callback.
  GestureConsecutiveTapCallback? onTap;

  /// A pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  ///
  /// This triggers once the gesture loses the arena if [onTapDown] has
  /// previously been triggered.
  ///
  /// If this recognizer wins the arena, [onTapUp] and [onTap] are called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
  ///  * [onTertiaryTapCancel], a similar callback but for a tertiary button.
  ///  * [GestureDetector.onTapCancel], which exposes this callback.
  GestureConsecutiveTapCancelCallback? onTapCancel;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        return (onTapDown != null
            || onTap != null
            || onTapUp != null
            || onTapCancel != null)
            && super.isPointerAllowed(event);
      default:
        return false;
    }
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    super.handleNonAllowedPointer(event);
    if (_tapSequenceTimer != null) {
      assert(_tapStatus?.tapUpDetails != null);
      _tapSequenceTimer?.cancel();
      _tapSequenceTimer = null;
      _tapStatus = null;
    }
  }

  @override
  String get debugDescription => 'consecutive taps on editable text';

  @override
  void handleTapDown({required PointerDownEvent down}) {
    final TapDownDetails details = TapDownDetails(
      globalPosition: down.position,
      localPosition: down.localPosition,
      kind: getKindForPointer(down.pointer),
    );

    assert(down.buttons == kPrimaryButton);
    final _TapTextGestureStatus? tapStatus = _tapStatus;
    final GestureConsecutiveTapDownCallback? onTapDown = this.onTapDown;

    if (tapStatus == null) {
      _tapStatus = _TapTextGestureStatus._(details);
      if (onTapDown != null) {
        invokeCallback<void>('onTapDown', () => onTapDown(details, 1));
      }
      return;
    }

    assert(!tapStatus.isCancelled);
    final TapUpDetails? previousTapUp = tapStatus.tapUpDetails;
    assert((_tapSequenceTimer == null) == (tapStatus.tapDownCount == 0));
    assert((previousTapUp == null) == (tapStatus.tapDownCount == 0));

    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;

    final bool isConsecutiveTap = previousTapUp != null
                                && previousTapUp.kind == details.kind
                                // Uses global position so that if a text field
                                // relocates the tap down misses.
                                && (previousTapUp.globalPosition - details.globalPosition).distance <= kDoubleTapSlop;

    // Update public status.
    tapStatus._tapDownCount = isConsecutiveTap ? tapStatus.tapDownCount + 1 : 1;
    tapStatus._tapDownDetails = details;
    tapStatus._tapUpDetails = null;

    if (onTapDown != null) {
      invokeCallback<void>('onTapDown', () => onTapDown(details, tapStatus.tapDownCount));
    }
  }

  @override
  void handleTapUp({required PointerDownEvent down, required PointerUpEvent up}) {
    final TapUpDetails details = TapUpDetails(
      kind: up.kind,
      globalPosition: up.position,
      localPosition: up.localPosition,
    );

    assert(_tapSequenceTimer == null);
    final _TapTextGestureStatus? tapStatus = _tapStatus;
    if (tapStatus == null) {
      assert(false, 'tap up without a tap down');
      return;
    }

    assert(!tapStatus.isCancelled);
    assert(tapStatus.tapUpDetails == null);
    tapStatus._tapUpDetails = details;
    final GestureConsecutiveTapUpCallback? onTapUp = this.onTapUp;
    final GestureConsecutiveTapCallback? onTap = this.onTap;
    if (onTapUp != null) {
      invokeCallback<void>('onTapUp', () => onTapUp.call(details, tapStatus.tapDownCount));
    }
    if (onTap != null) {
      invokeCallback<void>('onTap', () => onTap.call(tapStatus.tapDownDetails, details, tapStatus.tapDownCount));
    }
    _tapSequenceTimer = Timer(kDoubleTapTimeout, _onConsecutiveTapsEnd);
  }

  @override
  void handleTapCancel({required PointerDownEvent down, PointerCancelEvent? cancel, required String reason}) {
    final String note = reason == '' ? reason : '$reason ';
    assert(_tapSequenceTimer == null);
    final _TapTextGestureStatus? tapStatus = _tapStatus;
    if (tapStatus == null) {
      assert(false, 'tap cancel without a tap down');
      return;
    }

    assert(!tapStatus.isCancelled);
    assert(tapStatus.tapUpDetails == null);
    tapStatus._isCancelled = true;
    final GestureConsecutiveTapCancelCallback? onTapCancel = this.onTapCancel;
    if (onTapCancel != null) {
      invokeCallback<void>('${note}onTapCancel', () => onTapCancel(tapStatus.tapDownCount));
    }
    _tapStatus = null;
  }

  void _onConsecutiveTapsEnd() {
    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;
    _tapStatus = null;
  }

  @override
  void dispose() {
    _tapSequenceTimer?.cancel();
    _tapSequenceTimer = null;
    super.dispose();
  }
}
