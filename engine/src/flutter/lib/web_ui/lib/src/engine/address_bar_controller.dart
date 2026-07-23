// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'dom.dart';
import 'platform_dispatcher.dart';
import 'pointer_binding.dart';
import 'pointer_converter.dart';
import 'semantics.dart';
import 'view_embedder/embedding_strategy/full_page_embedding_strategy.dart';
import 'window.dart';

/// Enables mobile browser address bar collapse for Flutter web apps.
///
/// Flutter web sets `touch-action: none` on `<body>`, preventing the
/// browser from detecting scrolls. This class sets `touch-action: pan-y`
/// and adds a spacer to make `<body>` scrollable, allowing the browser
/// to collapse the address bar on scroll.
///
/// When active, finger input is taken from Touch Events (which keep firing
/// during scrolling) rather than touch-type Pointer Events (whose stream breaks
/// because `pan-y` fires `pointercancel` on vertical scrolls). Each touch is
/// converted to pointer data and handed to `PointerBinding`'s `ClickDebouncer`
/// directly; the native touch-type pointer events it replaces are stopped in
/// the window capture phase so `PointerBinding` does not process them too.
///
/// See also:
///
///  * https://github.com/flutter/flutter/issues/69529
class AddressBarController {
  AddressBarController(EngineFlutterView view)
    : _view = view,
      _isActive = _computeIsSupported(view) {
    if (!_isActive) {
      return;
    }

    _setupScrollMachinery();
    _setupTouchTranslation();
    _setupTouchPointerEventSuppression();
  }

  final EngineFlutterView _view;

  final bool _isActive;

  final List<_SavedStyle> _savedStyles = <_SavedStyle>[];

  static bool get _isIOs => ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs;
  static bool get _isAndroid => ui_web.browser.operatingSystem == ui_web.OperatingSystem.android;

  /// Whether the current operating system is one the address bar collapse
  /// targets (iOS or Android).
  ///
  /// [FullPageDimensionsProvider] reads this so its `innerHeight`-based height
  /// measurement is gated on exactly the operating systems this controller
  /// activates for, rather than on the broader [ui_web.BrowserDetection.isMobile]
  /// (which also includes [ui_web.OperatingSystem.unknown]).
  static bool get isSupportedOperatingSystem => _isIOs || _isAndroid;

  static bool _computeIsSupported(EngineFlutterView view) =>
      isSupportedOperatingSystem && view.embeddingStrategy is FullPageEmbeddingStrategy;

  DomElement? _spacerElement;

  void dispose() {
    if (!_isActive) {
      return;
    }
    _cancelActiveTouches();
    _removeListeners();
    _teardownScrollMachinery();
  }

  /// Makes the page scrollable so the browser collapses the address bar on
  /// scroll: a scrollable, `pan-y` `<body>`; scroll-snapping on `<html>`; and an
  /// off-screen spacer carrying the snap targets.
  void _setupScrollMachinery() {
    final DomCSSStyleDeclaration bodyStyle = domDocument.body!.style;
    _setStyle(bodyStyle, 'overflow-y', 'auto');
    _setStyle(bodyStyle, 'touch-action', 'pan-y');

    final DomCSSStyleDeclaration htmlStyle = domDocument.documentElement!.style;
    _setStyle(htmlStyle, 'scrollbar-width', 'none');

    final DomElement spacer = createDomElement('flt-scroll-spacer');
    spacer.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..width = '1px'
      ..pointerEvents = 'none'
      ..opacity = '0';
    _spacerElement = spacer;

    if (_isAndroid) {
      // Two snap targets: snap direction matches the user's scroll direction,
      // which Chrome requires for correct address bar detection, with
      // `proximity` strictness (`mandatory` re-snaps every frame and drops scroll
      // frames). Top snap at 1px prevents scrollTop=0 (pull-to-refresh).
      // collapseMargin keeps the bottom snap reachable after the address bar
      // collapses and the viewport grows (~80px). 100vh (the large viewport
      // height) keeps the spacer taller than the viewport across rotations.
      _setStyle(htmlStyle, 'scroll-snap-type', 'y proximity');
      const snapDistance = 100;
      const collapseMargin = 100;
      spacer.style.height = 'calc(100vh + ${snapDistance + 1 + collapseMargin}px)';
      spacer.append(_createSnapTarget(1));
      spacer.append(_createSnapTarget(snapDistance + 1));
    } else if (_isIOs) {
      // Single `mandatory` snap target at the midpoint prevents momentum
      // scrolling and keeps scrollTop far from 0 (no pull-to-refresh).
      _setStyle(htmlStyle, 'scroll-snap-type', 'y mandatory');
      const spacerHeight = 10000;
      spacer.style.height = '${spacerHeight}px';
      spacer.append(_createSnapTarget(spacerHeight ~/ 2));
    }

    domDocument.documentElement!.append(spacer);
  }

  /// Reverses [_setupScrollMachinery]: removes the spacer and restores the
  /// styles it changed.
  void _teardownScrollMachinery() {
    _spacerElement?.remove();
    _restoreStyles();
  }

  /// Sets [property] on [style] to [value], recording its prior value so
  /// [_restoreStyles] can put it back. Every `<body>`/`<html>` style mutation
  /// routes through here so the restore set can never drift from what setup
  /// changed.
  void _setStyle(DomCSSStyleDeclaration style, String property, String value) {
    _savedStyles.add((
      style: style,
      property: property,
      previousValue: style.getPropertyValue(property),
    ));
    style.setProperty(property, value);
  }

  /// Restores every property changed via [_setStyle] to its prior value;
  /// `setProperty` with an empty value removes a property that was unset.
  void _restoreStyles() {
    for (final _SavedStyle saved in _savedStyles) {
      saved.style.setProperty(saved.property, saved.previousValue);
    }
    _savedStyles.clear();
  }

  DomElement _createSnapTarget(int topOffset) {
    final DomElement target = createDomElement('flt-scroll-snap-target');
    target.style
      ..position = 'absolute'
      ..top = '${topOffset}px'
      ..left = '0'
      ..width = '1px'
      ..height = '1px'
      ..setProperty('scroll-snap-align', 'start');
    return target;
  }

  final List<_ListenerRegistration> _listenerRegistrations = <_ListenerRegistration>[];
  final Set<int> _activeTouchIds = <int>{};
  final PointerDataConverter _pointerDataConverter = PointerDataConverter();

  static const Map<String, String> _touchToPointerEventType = <String, String>{
    'touchstart': 'pointerdown',
    'touchmove': 'pointermove',
    'touchend': 'pointerup',
    'touchcancel': 'pointercancel',
  };

  /// Registers [handler] for [type] on [target] and tracks it so
  /// [_removeListeners] can detach it.
  void _addListener(
    DomEventTarget target,
    String type,
    DartDomEventListener handler,
    DomEventListenerOptions options,
  ) {
    final DomEventListener listener = createDomEventListener(handler);
    target.addEventListener(type, listener, options);
    _listenerRegistrations.add((target: target, type: type, listener: listener, options: options));
  }

  /// Reverses every [_addListener] from [_setupTouchTranslation] and
  /// [_setupTouchPointerEventSuppression].
  void _removeListeners() {
    for (final _ListenerRegistration registration in _listenerRegistrations) {
      registration.target.removeEventListener(
        registration.type,
        registration.listener,
        registration.options,
      );
    }
    _listenerRegistrations.clear();
  }

  /// Registers passive Touch Event listeners on the view root that feed
  /// [_translateTouchEvent].
  void _setupTouchTranslation() {
    _touchToPointerEventType.forEach((String touchEventType, String pointerEventType) {
      _addListener(
        _view.dom.rootElement,
        touchEventType,
        (DomEvent event) => _translateTouchEvent(event as DomTouchEvent, pointerEventType),
        DomEventListenerOptions(passive: true),
      );
    });
  }

  /// Stops the native touch-type pointer events that the translation replaces,
  /// so `PointerBinding` does not process each touch a second time.
  ///
  /// The capture phase on the window runs before any engine listener,
  /// regardless of registration order.
  void _setupTouchPointerEventSuppression() {
    for (final pointerEventType in <String>[..._touchToPointerEventType.values, 'pointerleave']) {
      _addListener(
        domWindow,
        pointerEventType,
        _suppressTouchPointerEvent,
        DomEventListenerOptions(capture: true),
      );
    }
  }

  /// Stops every native touch-type pointer event inside the view, and records
  /// pen (stylus) contacts. Mouse events pass through untouched.
  void _suppressTouchPointerEvent(DomEvent event) {
    final pointerEvent = event as DomPointerEvent;
    final String? pointerType = pointerEvent.pointerType;
    if (pointerType != 'touch' && pointerType != 'pen') {
      return;
    }
    final DomEventTarget? target = pointerEvent.target;
    if (target == null || !_view.dom.rootElement.contains(target as DomNode)) {
      return;
    }
    switch (pointerType) {
      case 'pen':
        _trackPenContact(pointerEvent);
      case 'touch':
        pointerEvent.stopPropagation();
        if (pointerEvent.type == 'pointerdown' && target == _view.dom.rootElement) {
          // Suppresses the browser's default focus change; the view focus is
          // requested from _translateTouchEvent instead.
          pointerEvent.preventDefault();
        }
    }
  }

  /// Positions of active stylus contacts, keyed by `pointerId`.
  final Map<int, ui.Offset> _activePenContacts = <int, ui.Offset>{};

  /// Records a stylus contact's position on `pointerdown` and clears it on
  /// `pointerup`/`pointercancel`/`pointerleave`, for [_coincidesWithActivePen].
  /// The pen's own Pointer events are left for `PointerBinding` to handle.
  void _trackPenContact(DomPointerEvent event) {
    final int? id = event.pointerId?.toInt();
    if (id == null) {
      return;
    }
    switch (event.type) {
      case 'pointerdown':
        _activePenContacts[id] = ui.Offset(event.clientX, event.clientY);
      case 'pointerup' || 'pointercancel' || 'pointerleave':
        _activePenContacts.remove(id);
    }
  }

  /// Whether [touch] coincides with an active stylus contact.
  ///
  /// One stylus contact fires both a `pen` Pointer event (kept, handled by
  /// `PointerBinding`) and a Touch event reporting the same position; the
  /// coinciding touch is skipped so one contact does not become two pointers.
  bool _coincidesWithActivePen(DomTouch touch) {
    const tolerance = 1.0;
    for (final ui.Offset pen in _activePenContacts.values) {
      if ((pen.dx - touch.clientX).abs() <= tolerance &&
          (pen.dy - touch.clientY).abs() <= tolerance) {
        return true;
      }
    }
    return false;
  }

  /// Converts a Touch Event into pointer data and hands it to PointerBinding's
  /// `ClickDebouncer` — the same entry the native pointer events would reach —
  /// without dispatching synthetic DOM events.
  void _translateTouchEvent(DomTouchEvent event, String pointerType) {
    // Report the event to semantics — it disables browser gestures while
    // pointer events are flowing and auto-enables semantics on interaction —
    // exactly as PointerBinding's listener wrapper does for the events it
    // handles. If semantics consumes the event, do not forward it.
    if (!EngineSemantics.instance.receiveGlobalEvent(event)) {
      return;
    }
    final ui.PointerChange change = switch (pointerType) {
      'pointerdown' => ui.PointerChange.down,
      'pointermove' => ui.PointerChange.move,
      'pointerup' => ui.PointerChange.up,
      _ => ui.PointerChange.cancel,
    };
    final bool isDown = change == ui.PointerChange.down || change == ui.PointerChange.move;
    final DomElement root = _view.dom.rootElement;
    final double dpr = _view.devicePixelRatio;
    final Duration timeStamp = _durationFromMilliseconds(event.timeStamp!);
    for (final DomTouch touch in event.changedTouches) {
      final int device = touch.identifier!.toInt();
      if (change == ui.PointerChange.down) {
        // The pen's pointerdown precedes this touchstart on the targeted
        // engines, so a coinciding contact is already recorded.
        if (_coincidesWithActivePen(touch)) {
          continue;
        }
        // A repeated touchstart for an already-active id would emit a second
        // down; skip it, as the native pointer path's sanitizer did.
        if (!_activeTouchIds.add(device)) {
          continue;
        }
      } else if (change == ui.PointerChange.move) {
        if (!_activeTouchIds.contains(device)) {
          continue;
        }
      } else if (!_activeTouchIds.remove(device)) {
        continue;
      }
      final data = <ui.PointerData>[];
      _pointerDataConverter.convert(
        data,
        viewId: _view.viewId,
        change: change,
        timeStamp: timeStamp,
        device: device,
        // In full-page mode the host is position:fixed at (0,0), so clientX/Y
        // are already root-relative. Reading getBoundingClientRect here to
        // re-derive the origin would force a synchronous layout flush on every
        // touchmove; during the address bar collapse the viewport resizes each
        // frame, so those reads thrash layout and stall the scroll.
        physicalX: touch.clientX * dpr,
        physicalY: touch.clientY * dpr,
        buttons: isDown ? 1 : 0,
        pressure: isDown ? 1.0 : 0.0,
        pressureMax: 1.0,
      );
      PointerBinding.clickDebouncer.onPointerData(
        _debounceEvent(pointerType, touch.target ?? root, event.timeStamp!),
        data,
      );
      if (change == ui.PointerChange.down && touch.target == root) {
        _requestViewFocus();
      }
    }
  }

  /// A minimal pointer-event-shaped object carrying only the fields
  /// `ClickDebouncer` reads (type, target, timeStamp); it is never dispatched.
  DomEvent _debounceEvent(String type, DomEventTarget target, num timeStamp) {
    final event = JSObject();
    event['type'] = type.toJS;
    event['target'] = target as JSObject;
    event['timeStamp'] = timeStamp.toJS;
    return event as DomEvent;
  }

  /// Focuses the view, replicating the side effect of PointerBinding's
  /// pointerdown handler, which no longer runs for touch input.
  void _requestViewFocus() {
    Timer(Duration.zero, () {
      EnginePlatformDispatcher.instance.requestViewFocusChange(
        viewId: _view.viewId,
        state: ui.ViewFocusState.focused,
        direction: ui.ViewFocusDirection.undefined,
      );
    });
  }

  static Duration _durationFromMilliseconds(num milliseconds) {
    final int ms = milliseconds.toInt();
    final int micro = ((milliseconds - ms) * Duration.microsecondsPerMillisecond).toInt();
    return Duration(milliseconds: ms, microseconds: micro);
  }

  /// Cancels touches still down so the framework does not keep phantom
  /// pointers after translation stops.
  void _cancelActiveTouches() {
    if (_activeTouchIds.isEmpty) {
      return;
    }
    final DomElement root = _view.dom.rootElement;
    for (final int device in _activeTouchIds) {
      final data = <ui.PointerData>[];
      // The converter substitutes the pointer's last known location for cancel.
      _pointerDataConverter.convert(data, viewId: _view.viewId, device: device, pressureMax: 1.0);
      // Route through the same ClickDebouncer entry as live touches. A cancel
      // issued mid-debounce is then queued behind the still-pending `down` and
      // flushed in order; sending it straight to the dispatcher would race
      // ahead of that queued `down` and leave the framework a phantom pointer.
      PointerBinding.clickDebouncer.onPointerData(_debounceEvent('pointercancel', root, 0), data);
    }
    _activeTouchIds.clear();
  }
}

typedef _ListenerRegistration = ({
  DomEventTarget target,
  String type,
  DomEventListener listener,
  DomEventListenerOptions options,
});

typedef _SavedStyle = ({DomCSSStyleDeclaration style, String property, String previousValue});
