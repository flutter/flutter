// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../engine.dart' show registerHotRestartListener;
import 'browser_detection.dart';
import 'dom.dart';
import 'platform_dispatcher.dart';
import 'pointer_converter.dart';
import 'safe_browser_api.dart';
import 'semantics.dart';

/// Set this flag to true to see all the fired events in the console.
const bool _debugLogPointerEvents = false;

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
  /// The singleton instance of this object.
  static PointerBinding? get instance => _instance;
  static PointerBinding? _instance;

  static void initInstance(DomElement glassPaneElement) {
    if (_instance == null) {
      _instance = PointerBinding(glassPaneElement);
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

  PointerBinding(this.glassPaneElement)
    : _pointerDataConverter = PointerDataConverter(),
      _detector = const PointerSupportDetector() {
    if (isIosSafari) {
      SafariPointerEventWorkaround.instance.workAroundMissingPointerEvents();
    }
    _adapter = _createAdapter();
  }

  final DomElement glassPaneElement;

  PointerSupportDetector _detector;
  PointerDataConverter _pointerDataConverter;
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

  _BaseAdapter _createAdapter() {
    if (_detector.hasPointerEvents) {
      return _PointerAdapter(_onPointerData, glassPaneElement, _pointerDataConverter);
    }
    if (_detector.hasTouchEvents) {
      return _TouchAdapter(_onPointerData, glassPaneElement, _pointerDataConverter);
    }
    if (_detector.hasMouseEvents) {
      return _MouseAdapter(_onPointerData, glassPaneElement, _pointerDataConverter);
    }
    throw UnsupportedError('This browser does not support pointer, touch, or mouse events.');
  }

  void _onPointerData(Iterable<ui.PointerData> data) {
    final ui.PointerDataPacket packet = ui.PointerDataPacket(data: data.toList());
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
  _BaseAdapter(this._callback, this.glassPaneElement, this._pointerDataConverter) {
    setup();
  }

  final List<_Listener> _listeners = <_Listener>[];
  final DomElement glassPaneElement;
  _PointerDataCallback _callback;
  PointerDataConverter _pointerDataConverter;

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
          print('${pointerEvent.type}    '
              '${pointerEvent.clientX.toStringAsFixed(1)},'
              '${pointerEvent.clientY.toStringAsFixed(1)}');
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

  List<ui.PointerData> _convertWheelEventToPointerData(
    DomWheelEvent event
  ) {
    const int domDeltaPixel = 0x00;
    const int domDeltaLine = 0x01;
    const int domDeltaPage = 0x02;

    // Flutter only supports pixel scroll delta. Convert deltaMode values
    // to pixels.
    double deltaX = event.deltaX as double;
    double deltaY = event.deltaY as double;
    switch (event.deltaMode) {
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
      default:
        break;
    }

    final List<ui.PointerData> data = <ui.PointerData>[];
    _pointerDataConverter.convert(
      data,
      change: ui.PointerChange.hover,
      timeStamp: _BaseAdapter._eventTimeStampToDuration(event.timeStamp!),
      kind: ui.PointerDeviceKind.mouse,
      signalKind: ui.PointerSignalKind.scroll,
      device: _mouseDeviceId,
      physicalX: event.clientX.toDouble() * ui.window.devicePixelRatio,
      physicalY: event.clientY.toDouble() * ui.window.devicePixelRatio,
      buttons: event.buttons!,
      pressure: 1.0,
      pressureMin: 0.0,
      pressureMax: 1.0,
      scrollDeltaX: deltaX,
      scrollDeltaY: deltaY,
    );
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
    _PointerDataCallback callback,
    DomElement glassPaneElement,
    PointerDataConverter pointerDataConverter
  ) : super(callback, glassPaneElement, pointerDataConverter);

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
  }) {
    addEventListener(target, eventName, (DomEvent event) {
      final DomPointerEvent pointerEvent = event as DomPointerEvent;
      handler(pointerEvent);
    }, useCapture: useCapture);
  }

  @override
  void setup() {
    _addPointerEventListener(glassPaneElement, 'pointerdown', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _ButtonSanitizer sanitizer = _ensureSanitizer(device);
      final _SanitizedDetails? up =
          sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!);
      if (up != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: up);
      }
      final _SanitizedDetails down =
        sanitizer.sanitizeDownEvent(
          button: event.button,
          buttons: event.buttons!,
        );
      _convertEventsToPointerData(data: pointerData, event: event, details: down);
      _callback(pointerData);
    });

    _addPointerEventListener(domWindow, 'pointermove', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      final _ButtonSanitizer sanitizer = _ensureSanitizer(device);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final List<DomPointerEvent> expandedEvents = _expandEvents(event);
      for (final DomPointerEvent event in expandedEvents) {
        final _SanitizedDetails? up = sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!);
        if (up != null) {
          _convertEventsToPointerData(data: pointerData, event: event, details: up);
        }
        final _SanitizedDetails move = sanitizer.sanitizeMoveEvent(buttons: event.buttons!);
        _convertEventsToPointerData(data: pointerData, event: event, details: move);
      }
      _callback(pointerData);
    });

    _addPointerEventListener(glassPaneElement, 'pointerleave', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      final _ButtonSanitizer sanitizer = _ensureSanitizer(device);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? details = sanitizer.sanitizeLeaveEvent(buttons: event.buttons!);
      if (details != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: details);
        _callback(pointerData);
      }
    }, useCapture: false);

    _addPointerEventListener(domWindow, 'pointerup', (DomPointerEvent event) {
      final int device = _getPointerId(event);
      if (_hasSanitizer(device)) {
        final List<ui.PointerData> pointerData = <ui.PointerData>[];
        final _SanitizedDetails? details = _getSanitizer(device).sanitizeUpEvent(buttons: event.buttons);
        _removePointerIfUnhoverable(event);
        if (details != null) {
          _convertEventsToPointerData(data: pointerData, event: event, details: details);
          _callback(pointerData);
        }
      }
    });

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
    });

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
    assert(data != null); // ignore: unnecessary_null_comparison
    assert(event != null); // ignore: unnecessary_null_comparison
    assert(details != null); // ignore: unnecessary_null_comparison
    final ui.PointerDeviceKind kind = _pointerTypeToDeviceKind(event.pointerType!);
    final double tilt = _computeHighestTilt(event);
    final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
    final num? pressure = event.pressure;
    _pointerDataConverter.convert(
      data,
      change: details.change,
      timeStamp: timeStamp,
      kind: kind,
      signalKind: ui.PointerSignalKind.none,
      device: _getPointerId(event),
      physicalX: event.clientX.toDouble() * ui.window.devicePixelRatio,
      physicalY: event.clientY.toDouble() * ui.window.devicePixelRatio,
      buttons: details.buttons,
      pressure:  pressure == null ? 0.0 : pressure.toDouble(),
      pressureMin: 0.0,
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
    return kind == ui.PointerDeviceKind.mouse ? _mouseDeviceId : event.pointerId!;
  }

  /// Tilt angle is -90 to + 90. Take maximum deflection and convert to radians.
  double _computeHighestTilt(DomPointerEvent e) =>
      (e.tiltX!.abs() > e.tiltY!.abs() ? e.tiltX : e.tiltY)!.toDouble() /
      180.0 *
      math.pi;
}

typedef _TouchEventListener = dynamic Function(DomTouchEvent event);

/// Adapter to be used with browsers that support touch events.
class _TouchAdapter extends _BaseAdapter {
  _TouchAdapter(
    _PointerDataCallback callback,
    DomElement glassPaneElement,
    PointerDataConverter pointerDataConverter
  ) : super(callback, glassPaneElement, pointerDataConverter);

  final Set<int> _pressedTouches = <int>{};
  bool _isTouchPressed(int identifier) => _pressedTouches.contains(identifier);
  void _pressTouch(int identifier) { _pressedTouches.add(identifier); }
  void _unpressTouch(int identifier) { _pressedTouches.remove(identifier); }

  void _addTouchEventListener(DomEventTarget target, String eventName, _TouchEventListener handler) {
    addEventListener(target, eventName, (DomEvent event) {
      final DomTouchEvent touchEvent = event as DomTouchEvent;
      handler(touchEvent);
    });
  }

  @override
  void setup() {
    _addTouchEventListener(glassPaneElement, 'touchstart', (DomTouchEvent event) {
      final Duration timeStamp = _BaseAdapter._eventTimeStampToDuration(event.timeStamp!);
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      for (final DomTouch touch in event.changedTouches!.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!);
        if (!nowPressed) {
          _pressTouch(touch.identifier!);
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
      for (final DomTouch touch in event.changedTouches!.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!);
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
      for (final DomTouch touch in event.changedTouches!.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!);
        if (nowPressed) {
          _unpressTouch(touch.identifier!);
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
      for (final DomTouch touch in event.changedTouches!.cast<DomTouch>()) {
        final bool nowPressed = _isTouchPressed(touch.identifier!);
        if (nowPressed) {
          _unpressTouch(touch.identifier!);
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
      kind: ui.PointerDeviceKind.touch,
      signalKind: ui.PointerSignalKind.none,
      device: touch.identifier!,
      physicalX: touch.clientX.toDouble() * ui.window.devicePixelRatio,
      physicalY: touch.clientY.toDouble() * ui.window.devicePixelRatio,
      buttons: pressed ? _kPrimaryMouseButton : 0,
      pressure: 1.0,
      pressureMin: 0.0,
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
    _PointerDataCallback callback,
    DomElement glassPaneElement,
    PointerDataConverter pointerDataConverter
  ) : super(callback, glassPaneElement, pointerDataConverter);

  final _ButtonSanitizer _sanitizer = _ButtonSanitizer();

  void _addMouseEventListener(
    DomEventTarget target,
    String eventName,
    _MouseEventListener handler, {
    bool useCapture = true,
  }) {
    addEventListener(target, eventName, (DomEvent event) {
      final DomMouseEvent mouseEvent = event as DomMouseEvent;
      handler(mouseEvent);
    }, useCapture: useCapture);
  }

  @override
  void setup() {
    _addMouseEventListener(glassPaneElement, 'mousedown', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? up =
          _sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!);
      if (up != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: up);
      }
      final _SanitizedDetails sanitizedDetails =
        _sanitizer.sanitizeDownEvent(
          button: event.button,
          buttons: event.buttons!,
        );
      _convertEventsToPointerData(data: pointerData, event: event, details: sanitizedDetails);
      _callback(pointerData);
    });

    _addMouseEventListener(domWindow, 'mousemove', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? up = _sanitizer.sanitizeMissingRightClickUp(buttons: event.buttons!);
      if (up != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: up);
      }
      final _SanitizedDetails move = _sanitizer.sanitizeMoveEvent(buttons: event.buttons!);
      _convertEventsToPointerData(data: pointerData, event: event, details: move);
      _callback(pointerData);
    });

    _addMouseEventListener(glassPaneElement, 'mouseleave', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? details = _sanitizer.sanitizeLeaveEvent(buttons: event.buttons!);
      if (details != null) {
        _convertEventsToPointerData(data: pointerData, event: event, details: details);
        _callback(pointerData);
      }
    }, useCapture: false);

    _addMouseEventListener(domWindow, 'mouseup', (DomMouseEvent event) {
      final List<ui.PointerData> pointerData = <ui.PointerData>[];
      final _SanitizedDetails? sanitizedDetails = _sanitizer.sanitizeUpEvent(buttons: event.buttons);
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
    assert(data != null); // ignore: unnecessary_null_comparison
    assert(event != null); // ignore: unnecessary_null_comparison
    assert(details != null); // ignore: unnecessary_null_comparison
    _pointerDataConverter.convert(
      data,
      change: details.change,
      timeStamp: _BaseAdapter._eventTimeStampToDuration(event.timeStamp!),
      kind: ui.PointerDeviceKind.mouse,
      signalKind: ui.PointerSignalKind.none,
      device: _mouseDeviceId,
      physicalX: event.clientX.toDouble() * ui.window.devicePixelRatio,
      physicalY: event.clientY.toDouble() * ui.window.devicePixelRatio,
      buttons: details.buttons,
      pressure: 1.0,
      pressureMin: 0.0,
      pressureMax: 1.0,
    );
  }
}
