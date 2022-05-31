import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class SelectionGestures extends StatefulWidget {
  const SelectionGestures({
    super.key,
    this.manager,
    required this.child,
    required this.gestures,
    this.behavior
  });

  final SelectionGesturesManager? manager;

  final Map<Type, ContextGestureRecognizerFactory> gestures;

  final Widget child;

  final HitTestBehavior? behavior;

  static SelectionGesturesManager of(BuildContext context) {
    assert(context != null);
    final _SelectionGesturesMarker? inherited = context.dependOnInheritedWidgetOfExactType<_SelectionGesturesMarker>();
    assert(() {
      if (inherited == null) {
        throw FlutterError(
            'Unable to find a SelectionGestures widget in the context.\n'
        );
      }
      return true;
    }());
    return inherited!.manager;
  }

  @override
  State<SelectionGestures> createState() => _SelectionGesturesState();
}

class _SelectionGesturesState extends State<SelectionGestures> {
  SelectionGesturesManager? _internalManager;
  SelectionGesturesManager get manager => widget.manager ?? _internalManager!;

  @override
  void initState() {
    super.initState();
    if (widget.manager == null) {
      _internalManager = SelectionGesturesManager();
    }
    manager.gestures = widget.gestures;
  }

  @override
  void dispose() {
    _internalManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionGesturesMarker(
      manager: manager,
      child: widget.child,
    );
  }
}

class SelectionGesturesManager extends ChangeNotifier {
  SelectionGesturesManager({
    Map<Type, ContextGestureRecognizerFactory> gestures = const <Type, ContextGestureRecognizerFactory>{},
  })  : assert(gestures != null),
        _gestures = gestures;
  
  Map<Type, ContextGestureRecognizerFactory> _gestures = <Type, ContextGestureRecognizerFactory>{};
  Map<Type, ContextGestureRecognizerFactory> get gestures => _gestures;
  set gestures(Map<Type, ContextGestureRecognizerFactory> gestures) {
    _gestures = gestures;
  }
 
  @protected
  void handlePointerDown(BuildContext context, PointerDownEvent event, Map<Type, GestureRecognizer> recognizers) {
    for (final GestureRecognizer recognizer in recognizers.values) {
      recognizer.addPointer(event);
    }
  }
}

class _SelectionGesturesMarker extends InheritedNotifier<SelectionGesturesManager> {
  const _SelectionGesturesMarker({
    required SelectionGesturesManager manager,
    required Widget child
  }) : super(notifier: manager, child: child);

  SelectionGesturesManager get manager => super.notifier!;
}

typedef ContextGestureRecognizerFactoryConstructor<T extends GestureRecognizer> = T Function(BuildContext context);

typedef ContextGestureRecognizerFactoryInitializer<T extends GestureRecognizer> = void Function(T instance, BuildContext context);

class ContextGestureRecognizerFactoryWithHandlers<T extends GestureRecognizer> extends ContextGestureRecognizerFactory<T> {
  /// Creates a gesture recognizer factory with the given callbacks.
  ///
  /// The arguments must not be null.
  const ContextGestureRecognizerFactoryWithHandlers(this._constructor, this._initializer)
      : assert(_constructor != null),
        assert(_initializer != null);

  final ContextGestureRecognizerFactoryConstructor<T> _constructor;

  final ContextGestureRecognizerFactoryInitializer<T> _initializer;

  @override
  T constructor(BuildContext context) => _constructor(context);

  @override
  void initializer(T instance, BuildContext context) => _initializer(instance, context);
}

@optionalTypeArgs
abstract class ContextGestureRecognizerFactory<T extends GestureRecognizer> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ContextGestureRecognizerFactory();

  /// Must return an instance of T.
  T constructor(BuildContext context);

  /// Must configure the given instance (which will have been created by
  /// `constructor`).
  ///
  /// This normally means setting the callbacks.
  void initializer(T instance, BuildContext context);

  bool _debugAssertTypeMatches(Type type) {
    assert(type == T, 'ContextGestureRecognizerFactory of type $T was used where type $type was specified.');
    return true;
  }
}

class _SelectionTapStatus {

}

typedef ConsecutiveSelectionTapGestureTapDownCallback = void Function(TapDownDetails details, bool isDoubleTap);
typedef ConsecutiveSelectionTapGestureTapUpCallback = void Function(TapUpDetails details, bool isDoubleTap);
typedef ConsecutiveSelectionTapGestureSecondaryTapCallback = void Function(Offset lastSecondaryTapDownPosition);

class SelectionConsecutiveTapGestureRecognizer extends BaseTapGestureRecognizer {
  /// Creates a tap gesture recognizer.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  SelectionConsecutiveTapGestureRecognizer({ super.debugOwner, super.supportedDevices });

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
  ConsecutiveSelectionTapGestureTapDownCallback? onTapDown;

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
  ConsecutiveSelectionTapGestureTapUpCallback? onTapUp;

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
  GestureTapCallback? onTap;

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
  GestureTapCancelCallback? onTapCancel;

  /// A pointer has stopped contacting the screen, which is recognized as a tap
  /// of a secondary button.
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it or
  /// has previously won, immediately following [onSecondaryTapUp].
  ///
  /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], which has the same timing but with details.
  ///  * [GestureDetector.onSecondaryTap], which exposes this callback.
  GestureTapCallback? onSecondaryTap;

  /// A pointer has contacted the screen at a particular location with a
  /// secondary button, which might be the start of a secondary tap.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
  /// next. Otherwise, [onSecondaryTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapDown], a similar callback but for a primary button.
  ///  * [onTertiaryTapDown], a similar callback but for a tertiary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onSecondaryTapDown], which exposes this callback.
  GestureTapDownCallback? onSecondaryTapDown;

  /// A pointer has stopped contacting the screen at a particular location,
  /// which is recognized as a tap of a secondary button.
  ///
  /// This triggers on the up event if the recognizer wins the arena with it
  /// or has previously won.
  ///
  /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [onSecondaryTap], a handler triggered right after this one that doesn't
  ///    pass any details about the tap.
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapUp], a similar callback but for a primary button.
  ///  * [onTertiaryTapUp], a similar callback but for a tertiary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onSecondaryTapUp], which exposes this callback.
  GestureTapUpCallback? onSecondaryTapUp;

  /// A pointer that previously triggered [onSecondaryTapDown] will not end up
  /// causing a tap.
  ///
  /// This triggers once the gesture loses the arena if [onSecondaryTapDown]
  /// has previously been triggered.
  ///
  /// If this recognizer wins the arena, [onSecondaryTapUp] is called instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapCancel], a similar callback but for a primary button.
  ///  * [onTertiaryTapCancel], a similar callback but for a tertiary button.
  ///  * [GestureDetector.onSecondaryTapCancel], which exposes this callback.
  GestureTapCancelCallback? onSecondaryTapCancel;

  /// A pointer has contacted the screen at a particular location with a
  /// tertiary button, which might be the start of a tertiary tap.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// If this recognizer doesn't win the arena, [onTertiaryTapCancel] is called
  /// next. Otherwise, [onTertiaryTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTapDown], a similar callback but for a primary button.
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTertiaryTapDown], which exposes this callback.
  GestureTapDownCallback? onTertiaryTapDown;

  /// A pointer has stopped contacting the screen at a particular location,
  /// which is recognized as a tap of a tertiary button.
  ///
  /// This triggers on the up event if the recognizer wins the arena with it
  /// or has previously won.
  ///
  /// If this recognizer doesn't win the arena, [onTertiaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTapUp], a similar callback but for a primary button.
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTertiaryTapUp], which exposes this callback.
  GestureTapUpCallback? onTertiaryTapUp;

  /// A pointer that previously triggered [onTertiaryTapDown] will not end up
  /// causing a tap.
  ///
  /// This triggers once the gesture loses the arena if [onTertiaryTapDown]
  /// has previously been triggered.
  ///
  /// If this recognizer wins the arena, [onTertiaryTapUp] is called instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapCancel], a similar callback but for a primary button.
  ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
  ///  * [GestureDetector.onTertiaryTapCancel], which exposes this callback.
  GestureTapCancelCallback? onTertiaryTapCancel;

  // For consecutive tap
  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;
  bool _isDoubleTap = false;
  int _tapCount = 0;

  bool _isWithinDoubleTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  void _doubleTapTimeout() {
    _doubleTapTimer = null;
    _lastTapOffset = null;
    _tapCount = 0;
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onTapDown == null &&
            onTap == null &&
            onTapUp == null &&
            onTapCancel == null)
          return false;
        break;
      case kSecondaryButton:
        if (onSecondaryTap == null &&
            onSecondaryTapDown == null &&
            onSecondaryTapUp == null &&
            onSecondaryTapCancel == null)
          return false;
        break;
      case kTertiaryButton:
        if (onTertiaryTapDown == null &&
            onTertiaryTapUp == null &&
            onTertiaryTapCancel == null)
          return false;
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @protected
  @override
  void handleTapDown({required PointerDownEvent down}) {
    final TapDownDetails details = TapDownDetails(
      globalPosition: down.position,
      localPosition: down.localPosition,
      kind: getKindForPointer(down.pointer),
    );

    if (_doubleTapTimer != null && _isWithinDoubleTapTolerance(details.globalPosition)) {
      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
      _tapCount += 1;
    }

    switch (down.buttons) {
      case kPrimaryButton:
        if (onTapDown != null)
          invokeCallback<void>('onTapDown', () => onTapDown!(details, _isDoubleTap));
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown != null)
          invokeCallback<void>('onSecondaryTapDown', () => onSecondaryTapDown!(details));
        break;
      case kTertiaryButton:
        if (onTertiaryTapDown != null)
          invokeCallback<void>('onTertiaryTapDown', () => onTertiaryTapDown!(details));
        break;
      default:
    }
  }

  @protected
  @override
  void handleTapUp({ required PointerDownEvent down, required PointerUpEvent up}) {
    final TapUpDetails details = TapUpDetails(
      kind: up.kind,
      globalPosition: up.position,
      localPosition: up.localPosition,
    );

    switch (down.buttons) {
      case kPrimaryButton:
        if (onTapUp != null)
          invokeCallback<void>('onTapUp', () => onTapUp!(details, _isDoubleTap ));
        if (onTap != null)
          invokeCallback<void>('onTap', onTap!);
        break;
      case kSecondaryButton:
        if (onSecondaryTapUp != null)
          invokeCallback<void>('onSecondaryTapUp', () => onSecondaryTapUp!(details));
        if (onSecondaryTap != null)
          invokeCallback<void>('onSecondaryTap', () => onSecondaryTap!());
        break;
      case kTertiaryButton:
        if (onTertiaryTapUp != null)
          invokeCallback<void>('onTertiaryTapUp', () => onTertiaryTapUp!(details));
        break;
      default:
    }

    if (!_isDoubleTap) {
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }
    _isDoubleTap = false;
  }

  @protected
  @override
  void handleTapCancel({ required PointerDownEvent down, PointerCancelEvent? cancel, required String reason }) {
    final String note = reason == '' ? reason : '$reason ';
    switch (down.buttons) {
      case kPrimaryButton:
        if (onTapCancel != null)
          invokeCallback<void>('${note}onTapCancel', onTapCancel!);
        break;
      case kSecondaryButton:
        if (onSecondaryTapCancel != null)
          invokeCallback<void>('${note}onSecondaryTapCancel', onSecondaryTapCancel!);
        break;
      case kTertiaryButton:
        if (onTertiaryTapCancel != null)
          invokeCallback<void>('${note}onTertiaryTapCancel', onTertiaryTapCancel!);
        break;
      default:
    }
  }

  @override
  String get debugDescription => 'tap';
}

/// Custom [SelectionGesturesManager] example, that logs the [PointerEvent]s.
class LoggingSelectionGesturesManager extends SelectionGesturesManager {
  @override
  void handlePointerDown(BuildContext context, PointerDownEvent event, Map<Type, GestureRecognizer> recognizers) {
    for(GestureRecognizer recognizer in recognizers.values) {
      if (recognizer.isPointerAllowed(event)) {
        print('Handled text selection gesture $recognizer $event in $context');
      }
    }
    super.handlePointerDown(context, event, recognizers);
  }
}