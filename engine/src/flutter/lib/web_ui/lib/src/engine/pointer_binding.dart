// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:ui/src/engine/keyboard_binding.dart';
import 'package:ui/ui.dart' as ui;

import '../engine.dart' show registerHotRestartListener;
import 'browser_detection.dart';
import 'dom.dart';
import 'platform_dispatcher.dart';
import 'pointer_binding/event_position_helper.dart';
import 'pointer_converter.dart';
import 'safe_browser_api.dart';
import 'semantics.dart';

/// Set this flag to true to log all the browser events.
const bool _debugLogPointerEvents = false;

/// Set this to true to log all the events sent to the Flutter framework.
const bool _debugLogFlutterEvents = false;

/// The signature of a callback that handles pointer events.
typedef _PointerDataCallback = void Function(Iterable<ui.PointerData>);

// The mask for the bitfield of event buttons. Buttons not contained in this
// mask are cut off.
//
// In Flutter we used `kMaxUnsignedSMI`, but since that value is not available
// here, we use an already very large number (30 bits).
const int _kButtonsMask = 0x3FFFFFFF;

// Intentionally set to -1 so it doesn't conflict with other device IDs.
const int _mouseDeviceId = -1;

const int _kPrimaryMouseButton = 0x1;
const int _kSecondaryMouseButton = 0x2;
const int _kMiddleMouseButton =0x4;

int _nthButton(int n) => 0x1 << n;

/// Convert the `button` property of PointerEvent or MouseEvent to a bit mask of
/// its `buttons` property.
///
/// The `button` property is a integer describing the button changed in an event,
/// which is sequentially 0 for LMB, 1 for MMB, 2 for RMB, 3 for backward and
/// 4 for forward, etc.
///
/// The `buttons` property is a bitfield describing the buttons pressed after an
/// event, which is 0x1 for LMB, 0x4 for MMB, 0x2 for RMB, 0x8 for backward
/// and 0x10 for forward, etc.
@visibleForTesting
int convertButtonToButtons(int button) {
  assert(button >= 0, 'Unexpected negative button $button.');
  switch(button) {
    case 0:
      return _kPrimaryMouseButton;
    case 1:
      return _kMiddleMouseButton;
    case 2:
      return _kSecondaryMouseButton;
    default:
      return _nthButton(button);
  }
}

/// Wrapping the Safari iOS workaround that adds a dummy event listener
/// More info about the issue and workaround: https://github.com/flutter/flutter/issues/70858
class SafariPointerEventWorkaround {
  static SafariPointerEventWorkaround instance = SafariPointerEventWorkaround();

  void workAroundMissingPointerEvents() {
    domDocument.addEventListener('touchstart', allowInterop((DomEvent event) {}));
  }
}

class PointerBinding {
  PointerBinding(this.glassPaneElement, this._keyboardConverter)
    : _pointerDataConverter = PointerDataConverter(),
      _detector = const PointerSupportDetector() {
    if (isIosSafari) {
      SafariPointerEventWorkaround.instance.workAroundMissingPointerEvents();
    }
    _adapter = _createAdapter();
  }

  /// The singleton instance of this object.
  static PointerBinding? get instance => _instance;
  static PointerBinding? _instance;

  static void initInstance(DomElement glassPaneElement, KeyboardConverter keyboardConverter) {
    if (_instance == null) {
      _instance = PointerBinding(glassPaneElement, keyboardConverter);
      assert(() {
        registerHotRestartListener(_instance!.dispose);
        return true;
      }());
    }
  }

  /// Performs necessary clean up for PointerBinding including removing event listeners
  /// and clearing the existing pointer state
  void dispose() {
    _adapter.clearListeners();
    _pointerDataConverter.clearPointerState();
  }

  final DomElement glassPaneElement;

  PointerSupportDetector _detector;
  final PointerDataConverter _pointerDataConverter;
  KeyboardConverter _keyboardConverter;
  late _BaseAdapter _adapter;

  /// Should be used in tests to define custom detection of pointer support.
  ///
  /// ```dart
  /// // Forces PointerBinding to use mouse events.
  /// class MyTestDetector extends PointerSupportDetector {
  ///   @override
  ///   final bool hasPointerEvents = false;
  ///
  ///   @override
  ///   final bool hasTouchEvents = false;
  ///
  ///   @override
  ///   final bool hasMouseEvents = true;
  /// }
  ///
  /// PointerBinding.instance.debugOverrideDetector(MyTestDetector());
  /// ```
  void debugOverrideDetector(PointerSupportDetector? newDetector) {
    newDetector ??= const PointerSupportDetector();
    // When changing the detector, we need to swap the adapter.
    if (newDetector != _detector) {
      _detector = newDetector;
      _adapter.clearListeners();
      _adapter = _createAdapter();
      _pointerDataConverter.clearPointerState();
    }
  }

  @visibleForTesting
  void debugOverrideKeyboardConverter(KeyboardConverter keyboardConverter) {
    _keyboardConverter = keyboardConverter;
    _adapter.clearListeners();
    _adapter = _createAdapter();
    _pointerDataConverter.clearPointerState();
  }

  // TODO(dit): remove old API fallbacks, https://github.com/flutter/flutter/issues/116141
  _BaseAdapter _createAdapter() {
    if (_detector.hasPointerEvents) {
      return _PointerAdapter(_onPointerData, glassPaneElement, _pointerDataConverter, _keyboardConverter);
    }
    // Fallback for Safari Mobile < 13. To be removed.
    if (_detector.hasTouchEvents) {
      return _TouchAdapter(_onPointerData, glassPaneElement, _pointerDataConverter, _keyboardConverter);
    }
    // Fallback for Safari Desktop < 13. To be removed.
    if (_detector.hasMouseEvents) {
      return _MouseAdapter(_onPointerData, glassPaneElement, _pointerDataConverter, _keyboardConverter);
    }
    throw UnsupportedError('This browser does not support pointer, touch, or mouse events.');
  }

  void _onPointerData(Iterable<ui.PointerData> data) {
    final ui.PointerDataPacket packet = ui.PointerDataPacket(data: data.toList());
    if (_debugLogFlutterEvents) {
      for(final ui.PointerData datum in data) {
        print('fw:${datum.change}    ${datum.physicalX},${datum.physicalY}');
      }
    }
    EnginePlatformDispatcher.instance.invokeOnPointerDataPacket(packet);
  }
}

class PointerSupportDetector {
  const PointerSupportDetector();

  bool get hasPointerEvents => hasJsProperty(domWindow, 'PointerEvent');
  bool get hasTouchEvents => hasJsProperty(domWindow, 'TouchEvent');
  bool get hasMouseEvents => hasJsProperty(domWindow, 'MouseEvent');

  @override
  String toString() =>
      'pointers:$hasPointerEvents, touch:$hasTouchEvents, mouse:$hasMouseEvents';
}

class _Listener {
  _Listener._({
    required this.event,
    required this.target,
    required this.handler,
    required this.useCapture,
    required this.isNative,
  });

  /// Registers a listener for the given [event] on [target] using the Dart-to-JS API.
  factory _Listener.register({
    required String event,
    required DomEventTarget target,
    required DomEventListener handler,
    bool capture = false,
  }) {
    final DomEventListener jsHandler = allowInterop((DomEvent event) => handler(event));
    final _Listener listener = _Listener._(
      event: event,
      target: target,
      handler: jsHandler,
      useCapture: capture,
      isNative: false,
    );
    target.addEventListener(event, jsHandler, capture);
    return listener;
  }

  /// Registers a listener for the given [event] on [target] using the native JS API.
  factory _Listener.registerNative({
    required String event,
    required DomEventTarget target,
    required DomEventListener handler,
    bool capture = false,
    bool passive = false,
  }) {
    final Object eventOptions = createPlainJsObject(<String, Object?>{
      'capture': capture,
      'passive': passive,
    });
    final DomEventListener jsHandler = allowInterop((DomEvent event) => handler(event));
    final _Listener listener = _Listener._(
      event: event,
      target: target,
      handler: jsHandler,
      useCapture: capture,
      isNative: true,
    );
    addJsEventListener(target, event, jsHandler, eventOptions);
    return listener;
  }

  final String event;

  final DomEventTarget target;
  final DomEventListener handler;

  final bool useCapture;
  final bool isNative;

  void unregister() {
    if (isNative) {
      removeJsEventListener(target, event, handler, useCapture);
    } else {
      target.removeEventListener(event, handler, useCapture);
    }
  }
}

/// Common functionality that's shared among adapters.
abstract class _BaseAdapter {
  _BaseAdapter(
    this._callback,
    this.glassPaneElement,
    this._pointerDataConverter,
    this._keyboardConverter,
  ) {
    setup();
  }

  final List<_Listener> _listeners = <_Listener>[];
  final DomElement glassPaneElement;
  final _PointerDataCallback _callback;
  final PointerDataConverter _pointerDataConverter;
  final KeyboardConverter _keyboardConverter;
  DomWheelEvent? _lastWheelEvent;
  bool _lastWheelEventWasTrackpad = false;

  /// Each subclass is expected to override this method to attach its own event
  /// listeners and convert events into pointer events.
  void setup();

  /// Remove all active event listeners.
  void clearListeners() {
    for (final _Listener listener in _listeners) {
      listener.unregister();
    }
    _listeners.clear();
  }

  /// Adds a listener for the given [eventName] to [target].
  ///
  /// Generally speaking, down and leave events should use [glassPaneElement]
  /// as the [target], while move and up events should use [domWindow]
  /// instead, because the browser doesn't fire the latter two for DOM elements
  /// when the pointer is outside the window.
  ///
  /// If [useCapture] is set to false, the event will be handled in the
  /// bubbling phase instead of the capture phase.
  /// See [DOM Level 3 Events][events] for a detailed explanation.
  ///
  /// [events]: https://www.w3.org/TR/DOM-Level-3-Events/#event-flow
  void addEventListener(
    DomEventTarget target,
    String eventName,
    DomEventListener handler, {
    bool useCapture = true,
  }) {
    dynamic loggedHandler(DomEvent event) {
      if (_debugLogPointerEvents) {
        if (domInstanceOfString(event, 'PointerEvent')) {
          final DomPointerEvent pointerEvent = event as DomPointerEvent;
          final ui.Offset offset = computeEventOffsetToTarget(event, glassPaneElement);
          print('${pointerEvent.type}    '
              '${offset.dx.toStringAsFixed(1)},'
              '${offset.dy.toStringAsFixed(1)}');
        } else {
          print(event.type);
        }
      }
      // Report the event to semantics. This information is used to debounce
      // browser gestures. Semantics tells us whether it is safe to forward
      // the event to the framework.
      if (EngineSemanticsOwner.instance.receiveGlobalEvent(event)) {
        handler(event);
      }
    }
    _listeners.add(_Listener.register(
      event: eventName,
      target: target,
      handler: loggedHandler,
      capture: useCapture,
    ));
  }

  /// Converts a floating number timestamp (in milliseconds) to a [Duration] by
  /// splitting it into two integer components: milliseconds + microseconds.
  static Duration _eventTimeStampToDuration(num milliseconds) {
    final int ms = milliseconds.toInt();
    final int micro =
    ((milliseconds - ms) * Duration.microsecondsPerMillisecond).toInt();
    return Duration(milliseconds: ms, microseconds: micro);
  }
}

mixin _WheelEventListenerMixin on _BaseAdapter {
  static double? _defaultScrollLineHeight;

  bool _isAcceleratedMouseWheelDelta(num delta, num? wheelDelta) {
    // On macOS, scrolling using a mouse wheel by default uses an acceleration
    // curve, so delta values ramp up and are not at fixed multiples of 120.
    // But in this case, the wheelDelta properties of the event still keep
    // their original values.
    // For all events without this acceleration curve applied, the wheelDelta
    // values are by convention three times greater than the delta values and with
    // the opposite sign.
    if (wheelDelta == null) {
      return false;
    }
    // Account for observed issues with integer truncation by allowing +-1px error.
    return (wheelDelta - (-3 * delta)).abs() > 1;
  }

  bool _isTrackpadEvent(DomWheelEvent event) {
    // This function relies on deprecated and non-standard implementation
    // details. Useful reference material can be found below.
    //
    // https://source.chromium.org/chromium/chromium/src/+/main:ui/events/event.cc
    // https://source.chromium.org/chromium/chromium/src/+/main:ui/events/cocoa/events_mac.mm
    // https://github.com/WebKit/WebKit/blob/main/Source/WebCore/platform/mac/PlatformEventFactoryMac.mm
    // https://searchfox.org/mozilla-central/source/dom/events/WheelEvent.h
    // https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousewheel
    if (browserEngine == BrowserEngine.firefox) {
      // Firefox has restricted the wheelDelta properties, they do not provide
      // enough information to accurately disambiguate trackpad events from mouse
      // wheel events.
      return false;
    }
    if (_isAcceleratedMouseWheelDelta(event.deltaX, event.wheelDeltaX) ||
        _isAcceleratedMouseWheelDelta(event.deltaY, event.wheelDeltaY)) {
      return false;
    }
    if (((event.deltaX % 120 == 0) && (event.deltaY % 120 == 0)) ||
        (((event.wheelDeltaX ?? 1) % 120 == 0) && ((event.wheelDeltaY ?? 1) % 120) == 0)) {
      // While not in any formal web standard, `blink` and `webkit` browsers use
      // a delta of 120 to represent one mouse wheel turn. If both dimensions of
      // the delta are divisible by 120, this event is probably from a mouse.
      // Checking if wheelDeltaX and wheelDeltaY are both divisible by 120
      // catches any macOS accelerated mouse wheel deltas which by random chance
      // are not caught by _isAcceleratedMouseWheelDelta.
      final num deltaXChange = (event.deltaX - (_lastWheelEvent?.deltaX ?? 0)).abs();
      final num deltaYChange = (event.deltaY - (_lastWheelEvent?.deltaY ?? 0)).abs();
      if ((_lastWheelEvent == null) ||
          (deltaXChange == 0 && deltaYChange == 0) ||
          !(deltaXChange < 20 && deltaYChange < 20)) {
        // A trackpad event might by chance have a delta of exactly 120, so
        // make sure this event does not have a similar delta to the previous
        // one before calling it a mouse event.
        if (event.timeStamp != null && _lastWheelEvent?.timeStamp != null) {
          // If the event has a large delta to the previous event, check if
          // it was preceded within 50 milliseconds by a trackpad event. This
          // handles unlucky 120-delta trackpad events during rapid movement.
          final num diffMs = event.timeStamp! - _lastWheelEvent!.timeStamp!;
          if (diffMs < 50 && _lastWheelEventWasTrackpad) {
            return true;
          }
        }
        return false;
      }
    }
    return true;
  }

  List<ui.PointerData> _convertWheelEventToPointerData(
    DomWheelEvent event
  ) {
    const int domDeltaPixel = 0x00;
    const int domDeltaLine = 0x01;
    const int domDeltaPage = 0x02;

    ui.PointerDeviceKind kind = ui.PointerDeviceKind.mouse;
    if (_isTrackpadEvent(event)) {
      kind = ui.PointerDeviceKind.trackpad;
    }

    // Flutter only supports pixel scroll delta. Convert deltaMode values
    // to pixels.
    double deltaX = event.deltaX;
    double deltaY = event.deltaY;
    switch (event.deltaMode.toInt()) {
      case domDeltaLine:
        _defaultScrollLineHeight ??= _computeDefaultScrollLineHeight();
        deltaX *= _defaultScrollLineHeight!;
        deltaY *= _defaultScrollLineHeight!;
        break;
      case domDeltaPage:
        deltaX *= ui.window.physicalSize.width;
        deltaY *= ui.window.physicalSize.height;
        break;
      case domDeltaPixel:
        if (operatingSystem == OperatingSystem.macOs && (isSafari || isFirefox)) {
          // Safari and Firefox seem to report delta in logical pixels while
          // Chrome uses physical pixels.
          deltaX *= ui.window.devicePixelRatio;
          deltaY *= ui.window.devicePixelRatio;
        }
        break;
      default:
        break;
    }

    final List<ui.PointerData> data = <ui.PointerData>[];
    final ui.Offset offset = computeEventOffsetToTarget(event, glassPaneElement);
    _pointerDataConverter.convert(
      data,
      change: ui.PointerChange.hover,
      timeStamp: _BaseAdapter._eventTimeStampToDuration(event.timeStamp!),
      kind: kind,
      signalKind: ui.PointerSignalKind.scroll,
      device: _mouseDeviceId,
      physicalX: offset.dx * ui.window.devicePixelRatio,
      physicalY: offset.dy * ui.window.devicePixelRatio,
      buttons: event.buttons!.toInt(),
      pressure: 1.0,
      pressureMax: 1.0,
      scrollDeltaX: deltaX,
      scrollDeltaY: deltaY,
    );
    _lastWheelEvent = event;
    _lastWheelEventWasTrackpad = kind == ui.PointerDeviceKind.trackpad;
    return data;
  }

  void _addWheelEventListener(DomEventListener handler) {
    _listeners.add(_Listener.registerNative(
      event: 'wheel',
      target: glassPaneElement,
      handler: (DomEvent event) => handler(event),
    ));
  }

  void _handleWheelEvent(DomEvent e) {
    assert(domInstanceOfString(e, 'WheelEvent'));
    final DomWheelEvent event = e as DomWheelEvent;
    if (_debugLogPointerEvents) {
      print(event.type);
    }
    _callback(_convertWheelEventToPointerData(event));
    if (event.getModifierState('Control') &&
        operatingSystem != OperatingSystem.macOs &&
        operatingSystem != OperatingSystem.iOs) {
      // Ignore Control+wheel events since the default handler
      // will change browser zoom level instead of scrolling.
      // The exception is MacOs where Control+wheel will still scroll and zoom.
      return;
    }
    // Prevent default so mouse wheel event doesn't get converted to
    // a scroll event that semantic nodes would process.
    //
    event.preventDefault();
  }

  /// For browsers that report delta line instead of pixels such as FireFox
  /// compute line height using the default font size.
  ///
  /// Use Firefox to test this code path.
  double _computeDefaultScrollLineHeight() {
    const double kFallbackFontHeight = 16.0;
    final DomHTMLDivElement probe = createDomHTMLDivElement();
    probe.style
        ..fontSize = 'initial'
        ..display = 'none';
    domDocument.body!.append(probe);
    String fontSize = domWindow.getComputedStyle(probe).fontSize;
    double? res;
    if (fontSize.contains('px')) {
       fontSize = fontSize.replaceAll('px', '');
       res = double.tryParse(fontSize);
    }
    probe.remove();
    return res == null ? kFallbackFontHeight : res / 4.0;
  }
}

@immutable
class _SanitizedDetails {
  const _SanitizedDetails({
    required this.buttons,
    required this.change,
  });

  final ui.PointerChange change;
  final int buttons;

  @override
  String toString() => '$runtimeType(change: $change, buttons: $buttons)';
}

class _ButtonSanitizer {
  int _pressedButtons = 0;

  /// Transform [DomPointerEvent.buttons] to Flutter's PointerEvent buttons.
  int _htmlButtonsToFlutterButtons(int buttons) {
    // Flutter's button definition conveniently matches that of JavaScript
    // from primary button (0x1) to forward button (0x10), which allows us to
    // avoid transforming it bit by bit.
    return buttons & _kButtonsMask;
  }

  /// Given [DomPointerEvent.button] and [DomPointerEvent.buttons], tries to
  /// infer the correct value for Flutter buttons.
  int _inferDownFlutterButtons(int button, int buttons) {
    if (buttons == 0 && button > -1) {
      // In some cases, the browser sends `buttons:0` in a down event. In such
      // case, we try to infer the value from `button`.
      buttons = convertButtonToButtons(button);
    }
    return _htmlButtonsToFlutterButtons(buttons);
  }

  _SanitizedDetails sanitizeDownEvent({
    required int button,
    required int buttons,
  }) {
    // If the pointer is already down, we just send a move event with the new
    // `buttons` value.
    if (_pressedButtons != 0) {
      return sanitizeMoveEvent(buttons: buttons);
    }

    _pressedButtons = _inferDownFlutterButtons(button, buttons);

    return _SanitizedDetails(
      change: ui.PointerChange.down,
      buttons: _pressedButtons,
    );
  }

  _SanitizedDetails sanitizeMoveEvent({required int buttons}) {
    final int newPressedButtons = _htmlButtonsToFlutterButtons(buttons);
    // This could happen when the user clicks RMB then moves the mouse quickly.
    // The brower sends a move event with `buttons:2` even though there's no
    // buttons down yet.
    if (_pressedButtons == 0 && newPressedButtons != 0) {
      return _SanitizedDetails(
        change: ui.PointerChange.hover,
        buttons: _pressedButtons,
      );
    }

    _pressedButtons = newPressedButtons;

    return _SanitizedDetails(
      change: _pressedButtons == 0
          ? ui.PointerChange.hover
          : ui.PointerChange.move,
      buttons: _pressedButtons,
    );
  }

  _SanitizedDetails? sanitizeMissingRightClickUp({required int buttons}) {
    final int newPressedButtons = _htmlButtonsToFlutterButtons(buttons);
    // This could happen when RMB is clicked and released but no pointerup
    // event was received because context menu was shown.
    if (_pressedButtons != 0 && newPressedButtons == 0) {
      _pressedButtons = 0;
      return _SanitizedDetails(
        change: ui.PointerChange.up,
        buttons: _pressedButtons,
      );
    }
    return null;
  }

  _SanitizedDetails? sanitizeLeaveEvent({required int buttons}) {
    final int newPressedButtons = _htmlButtonsToFlutterButtons(buttons);

    // The move event already handles the case where the pointer is currently
    // down, in which case handling the leave event as well is superfluous.
    if (newPressedButtons == 0) {
      _pressedButtons = 0;

      return _SanitizedDetails(
        change: ui.PointerChange.hover,
        buttons: _pressedButtons,
      );
    }

    return null;
  }

  _SanitizedDetails? sanitizeUpEvent({required int? buttons}) {
    // The pointer could have been released by a `pointerout` event, in which
    // case `pointerup` should have no effect.
    if (_pressedButtons == 0) {
      return null;
    }

    _pressedButtons = _htmlButtonsToFlutterButtons(buttons ?? 0);

    if (_pressedButtons == 0) {
      // All buttons have been released.
      return _SanitizedDetails(
        change: ui.PointerChange.up,
        buttons: _pressedButtons,
      );
    } else {
      // There are still some unreleased buttons, we shouldn't send an up event
      // yet. Instead we send a move event to update the position of the pointer.
      return _SanitizedDetails(
        change: ui.PointerChange.move,
        buttons: _pressedButtons,
      );
    }
  }

  _SanitizedDetails sanitizeCancelEvent() {
    _pressedButtons = 0;
    return _SanitizedDetails(
      change: ui.PointerChange.cancel,
      buttons: _pressedButtons,
    );
  }
}

typedef _PointerEventListener = dynamic Function(DomPointerEvent event);

/// Adapter class to be used with browsers that support native pointer events.
///
/// For the difference between MouseEvent and PointerEvent, see _MouseAdapter.
class _PointerAdapter extends _BaseAdapter with _WheelEventListenerMixin {
  _PointerAdapter(
    super.callback,
    super.glassPaneElement,
    super.pointerDataConverter,
    super.keyboardConverter,
  );

  final Map<int, _ButtonSanitizer> _sanitizers = <int, _ButtonSanitizer>{};

  @visibleForTesting
  Iterable<int> debugTrackedDevices() => _sanitizers.keys;

  _ButtonSanitizer _ensureSanitizer(int device) {
    return _sanitizers.putIfAbsent(device, () => _ButtonSanitizer());
  }

  _ButtonSanitizer _getSanitizer(int device) {
    assert(_sanitizers[device] != null);
    return _sanitizers[device]!;
  }

  bool _hasSanitizer(int device) {
    return _sanitizers.containsKey(device);
  }

  void _removePointerIfUnhoverable(DomPointerEvent event) {
    if (event.pointerType == 'touch') {
      _sanitizers.remove(event.pointerId);
    }
  }

  void _addPointerEventListener(
    DomEventTarget target,
    String eventName,
    _PointerEventListener handler, {
    bool useCapture = true,
    bool checkModifiers = true,
  }) {
    addEventListener(target, eventName, (DomEvent event) {
      final DomPointerEvent pointerEvent = event as DomPointerEvent;
      if (checkModifiers) {
        _checkModifiersState(event);
      }
      handler(pointerEvent);
    }, useCapture: useCapture);
  }

  void _checkModifiersState(DomPointerEvent event) {
    _keyboardConverter.synthesizeModifiersIfNeeded(
      event.getModifierState('Alt'),
      event.getModifierState('Control'),
      event.getModifierState('Meta'),
      event.getModifierState('Shift'),
      event.timeStamp!,
    );
  }

  @override
  void setup() {
    _addPointerEventListener(glassPaneElement, 'pointerdown', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _ButtonSanitizer sanitizer = _ensureSanitizer(device);
      final _SanitizedDetails? up =
          sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!.toInt());
      if (up != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: up);
      }
      final _SanitizedDetails down =
        sanitizer.sanitizeDownEvent(
          button: event.button.toInt(),
          buttons: event.buttons!.toInt(),
        );
      _convertEventsToPointerData(data: pointerData, event: event, details: down);
      _callback(pointerData);
    });

    // Why `domWindow` you ask? See this fiddle: https://jsfiddle.net/ditman/7towxaqp
    _addPointerEventListener(domWindow, 'pointermove', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      final _ButtonSanitizer sanitizer = _ensureSanitizer(device);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final List<DomPointerEvent> expandedEvents = _expandEvents(event);
      for (final DomPointerEvent event in expandedEvents) {
        final _SanitizedDetails? up = sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!.toInt());
        if (up != null) {
          _convertEventsToPointerData(data: pointerData, event: event, details: up);
        }
        final _SanitizedDetails move = sanitizer.sanitizeMoveEvent(buttons: event.buttons!.toInt());
        _convertEventsToPointerData(data: pointerData, event: event, details: move);
      }
      _callback(pointerData);
    });

    _addPointerEventListener(glassPaneElement, 'pointerleave', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      final _ButtonSanitizer sanitizer = _ensureSanitizer(device);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? details = sanitizer.sanitizeLeaveEvent(buttons: event.buttons!.toInt());
      if (details != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: details);
        _callback(pointerData);
      }
    }, useCapture: false, checkModifiers: false);

    // TODO(dit): This must happen in the glassPane, https://github.com/flutter/flutter/issues/116561
    _addPointerEventListener(domWindow, 'pointerup', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      if (_hasSanitizer(device)) {
        final List<ui.PointerData> pointerData = <ui.PointerData>[];
        final _SanitizedDetails? details = _getSanitizer(device).sanitizeUpEvent(buttons: event.buttons?.toInt());
        _removePointerIfUnhoverable(event);
        if (details != null) {
          _convertEventsToPointerData(data: pointerData, event: event, details: details);
          _callback(pointerData);
        }
      }
    });

    // TODO(dit): Synthesize a "cancel" event when 'pointerup' happens outside of the glassPane, https://github.com/flutter/flutter/issues/116561

    // A browser fires cancel event if it concludes the pointer will no longer
    // be able to generate events (example: device is deactivated)
    _addPointerEventListener(glassPaneElement, 'pointercancel', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      if (_hasSanitizer(device)) {
        final List<ui.PointerData> pointerData = <ui.PointerData>[];
        final _SanitizedDetails details = _getSanitizer(device).sanitizeCancelEvent();
        _removePointerIfUnhoverable(event);
        _convertEventsToPointerData(data: pointerData, event: event, details: details);
        _callback(pointerData);
      }
    }, checkModifiers: false);

    _addWheelEventListener((DomEvent event) {
      _handleWheelEvent(event);
    });
  }

  // For each event that is de-coalesced from `event` and described in
  // `details`, convert it to pointer data and store in `data`.
  void _convertEventsToPointerData({
    required List<ui.PointerData> data,
    required DomPointerEvent event,
    required _SanitizedDetails details,
  }) {
    final ui.PointerDeviceKind kind = _pointerTypeToDeviceKind(event.pointerType!);
    final double tilt = _computeHighestTilt(event);
    final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
    final num? pressure = event.pressure;
    final ui.Offset offset = computeEventOffsetToTarget(event, glassPaneElement);
    _pointerDataConverter.convert(
      data,
      change: details.change,
      timeStamp: timeStamp,
      kind: kind,
      signalKind: ui.PointerSignalKind.none,
      device: _getPointerId(event),
      physicalX: offset.dx * ui.window.devicePixelRatio,
      physicalY: offset.dy * ui.window.devicePixelRatio,
      buttons: details.buttons,
      pressure:  pressure == null ? 0.0 : pressure.toDouble(),
      pressureMax: 1.0,
      tilt: tilt,
    );
  }

  List<DomPointerEvent> _expandEvents(DomPointerEvent event) {
    // For browsers that don't support `getCoalescedEvents`, we fallback to
    // using the original event.
    if (hasJsProperty(event, 'getCoalescedEvents')) {
      final List<DomPointerEvent> coalescedEvents =
          event.getCoalescedEvents().cast<DomPointerEvent>();
      // Some events don't perform coalescing, so they return an empty list. In
      // that case, we also fallback to using the original event.
      if (coalescedEvents.isNotEmpty) {
        return coalescedEvents;
      }
    }
    // Important: coalesced events lack the `eventTarget` property (because they're
    // being handled in a deferred way).
    //
    // See the "Note" here: https://developer.mozilla.org/en-US/docs/Web/API/Event/currentTarget
    return <DomPointerEvent>[event];
  }

  ui.PointerDeviceKind _pointerTypeToDeviceKind(String pointerType) {
    switch (pointerType) {
      case 'mouse':
        return ui.PointerDeviceKind.mouse;
      case 'pen':
        return ui.PointerDeviceKind.stylus;
      case 'touch':
        return ui.PointerDeviceKind.touch;
      default:
        return ui.PointerDeviceKind.unknown;
    }
  }

  int _getPointerId(DomPointerEvent event) {
    // We force `device: _mouseDeviceId` on mouse pointers because Wheel events
    // might come before any PointerEvents, and since wheel events don't contain
    // pointerId we always assign `device: _mouseDeviceId` to them.
    final ui.PointerDeviceKind kind = _pointerTypeToDeviceKind(event.pointerType!);
    return kind == ui.PointerDeviceKind.mouse ? _mouseDeviceId :
        event.pointerId!.toInt();
  }

  /// Tilt angle is -90 to + 90. Take maximum deflection and convert to radians.
  double _computeHighestTilt(DomPointerEvent e) =>
      (e.tiltX!.abs() > e.tiltY!.abs() ? e.tiltX : e.tiltY)! /
      180.0 *
      math.pi;
}

typedef _TouchEventListener = dynamic Function(DomTouchEvent event);

/// Adapter to be used with browsers that support touch events.
class _TouchAdapter extends _BaseAdapter {
  _TouchAdapter(
    super.callback,
    super.glassPaneElement,
    super.pointerDataConverter,
    super.keyboardConverter,
  );

  final Set<int> _pressedTouches = <int>{};
  bool _isTouchPressed(int identifier) => _pressedTouches.contains(identifier);
  void _pressTouch(int identifier) { _pressedTouches.add(identifier); }
  void _unpressTouch(int identifier) { _pressedTouches.remove(identifier); }

  void _addTouchEventListener(DomEventTarget target, String eventName, _TouchEventListener handler, {bool checkModifiers = true,}) {
    addEventListener(target, eventName, (DomEvent event) {
      final DomTouchEvent touchEvent = event as DomTouchEvent;
      if (checkModifiers) {
        _checkModifiersState(event);
      }
      handler(touchEvent);
    });
  }

  void _checkModifiersState(DomTouchEvent event) {
    _keyboardConverter.synthesizeModifiersIfNeeded(
      event.altKey,
      event.ctrlKey,
      event.metaKey,
      event.shiftKey,
      event.timeStamp!,
    );
  }

  @override
  void setup() {
    _addTouchEventListener(glassPaneElement, 'touchstart', (DomTouchEvent event) {
      final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      for (final DomTouch touch in event.changedTouches.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!.toInt());
        if (!nowPressed) {
          _pressTouch(touch.identifier!.toInt());
          _convertEventToPointerData(
            data: pointerData,
            change: ui.PointerChange.down,
            touch: touch,
            pressed: true,
            timeStamp: timeStamp,
          );
        }
      }
      _callback(pointerData);
    });

    _addTouchEventListener(glassPaneElement, 'touchmove', (DomTouchEvent event) {
      event.preventDefault(); // Prevents standard overscroll on iOS/Webkit.
      final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      for (final DomTouch touch in event.changedTouches.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!.toInt());
        if (nowPressed) {
          _convertEventToPointerData(
            data: pointerData,
            change: ui.PointerChange.move,
            touch: touch,
            pressed: true,
            timeStamp: timeStamp,
          );
        }
      }
      _callback(pointerData);
    });

    _addTouchEventListener(glassPaneElement, 'touchend', (DomTouchEvent event) {
      // On Safari Mobile, the keyboard does not show unless this line is
      // added.
      event.preventDefault();
      final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      for (final DomTouch touch in event.changedTouches.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!.toInt());
        if (nowPressed) {
          _unpressTouch(touch.identifier!.toInt());
          _convertEventToPointerData(
            data: pointerData,
            change: ui.PointerChange.up,
            touch: touch,
            pressed: false,
            timeStamp: timeStamp,
          );
        }
      }
      _callback(pointerData);
    });

    _addTouchEventListener(glassPaneElement, 'touchcancel', (DomTouchEvent event) {
      final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      for (final DomTouch touch in event.changedTouches.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!.toInt());
        if (nowPressed) {
          _unpressTouch(touch.identifier!.toInt());
          _convertEventToPointerData(
            data: pointerData,
            change: ui.PointerChange.cancel,
            touch: touch,
            pressed: false,
            timeStamp: timeStamp,
          );
        }
      }
      _callback(pointerData);
    });
  }

  void _convertEventToPointerData({
    required List<ui.PointerData> data,
    required ui.PointerChange change,
    required DomTouch touch,
    required bool pressed,
    required Duration timeStamp,
  }) {
    _pointerDataConverter.convert(
      data,
      change: change,
      timeStamp: timeStamp,
      signalKind: ui.PointerSignalKind.none,
      device: touch.identifier!.toInt(),
      // Account for zoom/scroll in the TouchEvent
      physicalX: touch.clientX * ui.window.devicePixelRatio,
      physicalY: touch.clientY * ui.window.devicePixelRatio,
      buttons: pressed ? _kPrimaryMouseButton : 0,
      pressure: 1.0,
      pressureMax: 1.0,
    );
  }
}

typedef _MouseEventListener = dynamic Function(DomMouseEvent event);

/// Adapter to be used with browsers that support mouse events.
///
/// The difference between MouseEvent and PointerEvent can be illustrated using
/// a scenario of changing buttons during a drag sequence: LMB down, RMB down,
/// move, LMB up, RMB up, hover.
///
///                 LMB down    RMB down      move      LMB up      RMB up     hover
/// PntEvt type | pointerdown pointermove pointermove pointermove pointerup pointermove
///      button |      0           2           -1         0           2          -1
///     buttons |     0x1         0x3         0x3        0x2         0x0        0x0
/// MosEvt type |  mousedown   mousedown   mousemove   mouseup     mouseup   mousemove
///      button |      0           2           0          0           2          0
///     buttons |     0x1         0x3         0x3        0x2         0x0        0x0
///
/// The major differences are:
///
///  * The type of events for changing buttons during a drag sequence.
///  * The `button` for dragging or hovering.
class _MouseAdapter extends _BaseAdapter with _WheelEventListenerMixin {
  _MouseAdapter(
    super.callback,
    super.glassPaneElement,
    super.pointerDataConverter,
    super.keyboardConverter,
  );

  final _ButtonSanitizer _sanitizer = _ButtonSanitizer();

  void _addMouseEventListener(
    DomEventTarget target,
    String eventName,
    _MouseEventListener handler, {
    bool useCapture = true,
    bool checkModifiers = true,
  }) {
    addEventListener(target, eventName, (DomEvent event) {
      final DomMouseEvent mouseEvent = event as DomMouseEvent;
      if (checkModifiers) {
        _checkModifiersState(event);
      }
      handler(mouseEvent);
    }, useCapture: useCapture);
  }

  void _checkModifiersState(DomMouseEvent event) {
    _keyboardConverter.synthesizeModifiersIfNeeded(
      event.getModifierState('Alt'),
      event.getModifierState('Control'),
      event.getModifierState('Meta'),
      event.getModifierState('Shift'),
      event.timeStamp!,
    );
  }

  @override
  void setup() {
    _addMouseEventListener(glassPaneElement, 'mousedown', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? up =
          _sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!.toInt());
      if (up != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: up);
      }
      final _SanitizedDetails sanitizedDetails =
        _sanitizer.sanitizeDownEvent(
          button: event.button.toInt(),
          buttons: event.buttons!.toInt(),
        );
      _convertEventsToPointerData(data: pointerData, event: event, details: sanitizedDetails);
      _callback(pointerData);
    });

    // Why `domWindow` you ask? See this fiddle: https://jsfiddle.net/ditman/7towxaqp
    _addMouseEventListener(domWindow, 'mousemove', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? up = _sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!.toInt());
      if (up != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: up);
      }
      final _SanitizedDetails move = _sanitizer.sanitizeMoveEvent(buttons: event.buttons!.toInt());
      _convertEventsToPointerData(data: pointerData, event: event, details: move);
      _callback(pointerData);
    });

    _addMouseEventListener(glassPaneElement, 'mouseleave', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? details = _sanitizer.sanitizeLeaveEvent(buttons: event.buttons!.toInt());
      if (details != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: details);
        _callback(pointerData);
      }
    }, useCapture: false);

    // TODO(dit): This must happen in the glassPane, https://github.com/flutter/flutter/issues/116561
    _addMouseEventListener(domWindow, 'mouseup', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? sanitizedDetails = _sanitizer.sanitizeUpEvent(buttons: event.buttons?.toInt());
      if (sanitizedDetails != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: sanitizedDetails);
        _callback(pointerData);
      }
    });

    _addWheelEventListener((DomEvent event) {
      _handleWheelEvent(event);
    });
  }

  // For each event that is de-coalesced from `event` and described in
  // `detailsList`, convert it to pointer data and store in `data`.
  void _convertEventsToPointerData({
    required List<ui.PointerData> data,
    required DomMouseEvent event,
    required _SanitizedDetails details,
  }) {
    final ui.Offset offset = computeEventOffsetToTarget(event, glassPaneElement);
    _pointerDataConverter.convert(
      data,
      change: details.change,
      timeStamp: _BaseAdapter._eventTimeStampToDuration(event.timeStamp!),
      kind: ui.PointerDeviceKind.mouse,
      signalKind: ui.PointerSignalKind.none,
      device: _mouseDeviceId,
      physicalX: offset.dx * ui.window.devicePixelRatio,
      physicalY: offset.dy * ui.window.devicePixelRatio,
      buttons: details.buttons,
      pressure: 1.0,
      pressureMax: 1.0,
    );
  }
}
