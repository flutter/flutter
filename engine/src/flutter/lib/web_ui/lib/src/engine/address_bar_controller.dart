// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

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
/// Flutter web sets `touch-action: none` on `<body>`, preventing the browser
/// from detecting scrolls. On Android and iOS, for a full-page app, this class
/// sets `touch-action: pan-y` and adds a spacer to make the page scrollable,
/// which is what the browser needs before it will collapse its address bar.
///
/// Under `pan-y` the browser fires `pointercancel` and stops reporting a finger
/// as soon as it claims a vertical drag for scrolling, but Touch Events keep
/// firing. So for touch input this class translates Touch Events into pointer
/// data and sends it to the framework itself. The browser throttles `touchmove`
/// while it is scrolling, so movement is taken from `pointerrawupdate` where it
/// can be — the browser has to fire it, and only one finger can be down, since a
/// raw update carries no id to match it to a contact. Mouse and stylus Pointer
/// Events are not intercepted and still go through `PointerBinding`.
///
/// The view is painted to the viewport with the address bar collapsed, so its
/// size does not change as the bar animates. What the bar covers is reported
/// through [EngineFlutterView.updateChromeInsets] as padding instead.
///
/// See: https://github.com/flutter/flutter/issues/69529
class AddressBarController {
  AddressBarController(EngineFlutterView view)
    : _view = view,
      _isActive = _computeIsSupported(view) {
    if (!_isActive) {
      return;
    }

    _setupScrollMachinery();
    _setupTouchTranslation();
    _setupNativePointerEventInterception();
    _measureChromeInsets(0);
  }

  final EngineFlutterView _view;

  final bool _isActive;

  static bool get isSupportedOperatingSystem => switch (ui_web.browser.operatingSystem) {
    ui_web.OperatingSystem.android || ui_web.OperatingSystem.iOs => true,
    _ => false,
  };

  static bool _computeIsSupported(EngineFlutterView view) =>
      isSupportedOperatingSystem && view.embeddingStrategy is FullPageEmbeddingStrategy;

  DomElement? _spacerElement;

  void dispose() {
    _cancelActiveTouches();
    _removeListeners();
    _spacerElement?.remove();
  }

  /// Makes the page scrollable so the browser collapses the address bar on
  /// scroll.
  void _setupScrollMachinery() {
    final DomCSSStyleDeclaration bodyStyle = domDocument.body!.style;
    // Propagates to the viewport, undoing the embedding strategy's `hidden`.
    bodyStyle.setProperty('overflow-y', 'auto');
    bodyStyle.setProperty('touch-action', 'pan-y');
    bodyStyle.setProperty('height', '100vh');

    final DomElement spacer = createDomElement('flt-scroll-spacer');
    spacer.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..width = '1px'
      ..pointerEvents = 'none'
      ..opacity = '0';
    _spacerElement = spacer;

    final DomCSSStyleDeclaration htmlStyle = domDocument.documentElement!.style;
    htmlStyle.setProperty('scrollbar-width', 'none');

    switch (ui_web.browser.operatingSystem) {
      case ui_web.OperatingSystem.android:
        // Chrome does not collapse the address bar under `mandatory`. The range
        // must also stay short: `100lvh` is the viewport with the chrome hidden
        // and the scrollport is the viewport with it showing, so this is the
        // chrome's height plus a pixel. Anything taller keeps scrolling the page
        // after the chrome is gone.
        htmlStyle.setProperty('scroll-snap-type', 'y proximity');
        spacer.style.height = 'calc(100lvh + 1px)';
        spacer.append(_createSnapTarget(1));
      case ui_web.OperatingSystem.iOs:
        // On iOS the snapping is for the scroll range, not the bar: `mandatory`
        // parks the page in the middle of a tall spacer, out of reach of
        // pull-to-refresh and rubber-banding (`overscroll-behavior` does not
        // prevent them there), and it cuts Safari's momentum scrolling short.
        htmlStyle.setProperty('scroll-snap-type', 'y mandatory');
        const spacerHeight = 10000;
        spacer.style.height = '${spacerHeight}px';
        spacer.append(_createSnapTarget(spacerHeight ~/ 2));
      default:
      // not supported
    }

    domDocument.documentElement!.append(spacer);
  }

  /// Called by [EngineFlutterView] on every browser resize, after it has
  /// recomputed `viewInsets`.
  void handleBrowserResize(ViewPadding viewInsets) {
    if (!_isActive) {
      return;
    }
    _measureChromeInsets(viewInsets.bottom);
  }

  void _measureChromeInsets(double keyboardInset) {
    final double dpr = _view.devicePixelRatio;
    final double bodyHeight = domDocument.body!.getBoundingClientRect().height;
    // The body's box is the viewport with the bar collapsed and the layout
    // viewport is the viewport with it showing, neither of which the keyboard
    // changes, so their difference is the strip the bar covers when it is out.
    final double barHeight =
        math.max(0.0, bodyHeight - domDocument.documentElement!.clientHeight) * dpr;
    // What it covers at this moment. The visual viewport is preferred over
    // `innerHeight`, which keeps the value it had when the gesture started until
    // the finger lifts. It shrinks for the keyboard too, which is already
    // reported as an inset, and for a pinch zoom, which `scale` takes back out.
    final DomVisualViewport? viewport = domWindow.visualViewport;
    final double visibleHeight = viewport == null
        ? domWindow.innerHeight!
        : viewport.height! * (viewport.scale ?? 1);
    final double covered = math.max(0.0, (bodyHeight - visibleHeight) * dpr - keyboardInset);
    _view.updateChromeInsets(
      padding: ViewPadding(bottom: math.min(covered, barHeight), left: 0, right: 0, top: 0),
      viewPadding: ViewPadding(bottom: barHeight, left: 0, right: 0, top: 0),
    );
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

  static const Map<String, ui.PointerChange> _touchEventChanges = <String, ui.PointerChange>{
    'touchstart': ui.PointerChange.down,
    'touchmove': ui.PointerChange.move,
    'touchend': ui.PointerChange.up,
    'touchcancel': ui.PointerChange.cancel,
  };

  /// The pointer events the Touch Event translation replaces.
  static const List<String> _interceptedPointerEventTypes = <String>[
    'pointerdown',
    'pointermove',
    'pointerup',
    'pointercancel',
    'pointerleave',
  ];

  void _addListener(
    DomEventTarget target,
    String type,
    DartDomEventListener handler,
    DomEventListenerOptions options,
  ) {
    final DomEventListener listener = createDomEventListener(handler);
    target.addEventListener(type, listener, options);
    _listenerRegistrations.add((target: target, type: type, listener: listener));
  }

  void _removeListeners() {
    for (final _ListenerRegistration registration in _listenerRegistrations) {
      registration.target.removeEventListener(registration.type, registration.listener);
    }
    _listenerRegistrations.clear();
  }

  void _setupTouchTranslation() {
    final options = DomEventListenerOptions(passive: true);
    _touchEventChanges.forEach((String touchEventType, ui.PointerChange change) {
      _addListener(
        _view.dom.rootElement,
        touchEventType,
        (DomEvent event) => _translateTouchEvent(event as DomTouchEvent, change),
        options,
      );
    });
    // On the window, where [PointerBinding] also listens for moves in full-page
    // mode.
    _addListener(domWindow, 'pointerrawupdate', _translateRawUpdate, options);
  }

  /// The contact whose movement `pointerrawupdate` is reporting, making its
  /// `touchmove` redundant. Which browsers send raw updates is decided by what
  /// arrives rather than by feature detection.
  int? _rawUpdatedContact;

  void _translateRawUpdate(DomEvent event) {
    final pointerEvent = event as DomPointerEvent;
    // Only while a single finger is down. A raw update carries no id this
    // translation can match to a contact, so with more than one down there is no
    // telling which finger moved; their `touchmove`s, which do carry ids, take
    // over.
    if (pointerEvent.pointerType != 'touch' || _activeTouchIds.length != 1) {
      return;
    }
    // Not reported to semantics: it neither consumes `pointerrawupdate` nor
    // counts it towards the gesture mode, and the contact's Touch Events are
    // reported already.
    final int device = _activeTouchIds.first;
    _rawUpdatedContact = device;
    final data = <ui.PointerData>[];
    final double dpr = _view.devicePixelRatio;
    _pointerDataConverter.convert(
      data,
      viewId: _view.viewId,
      change: ui.PointerChange.move,
      timeStamp: _durationFromMilliseconds(pointerEvent.timeStamp!),
      device: device,
      physicalX: pointerEvent.clientX * dpr,
      physicalY: pointerEvent.clientY * dpr,
      buttons: 1,
      pressure: pointerEvent.pressure ?? _fingerPressure,
      pressureMax: 1.0,
    );
    PointerBinding.clickDebouncer.onPointerData(pointerEvent, data);
  }

  /// Stops the touch-type pointer events that the Touch Event translation
  /// replaces from reaching [PointerBinding].
  ///
  /// `stopImmediatePropagation`, not `stopPropagation`: [PointerBinding] listens
  /// on this element too, and only the immediate form withholds the events from
  /// it, which works because [EngineFlutterView] constructs this controller
  /// first. Stopping here also keeps them from the window, where
  /// [PointerBinding] takes moves and ups. The bubble phase, rather than capture
  /// on the window, leaves platform views and native text fields their events.
  void _setupNativePointerEventInterception() {
    // Not passive: the handler calls `preventDefault`.
    final options = DomEventListenerOptions(passive: false);
    for (final String pointerEventType in _interceptedPointerEventTypes) {
      _addListener(_view.dom.rootElement, pointerEventType, _interceptNativePointerEvent, options);
    }
  }

  /// The withheld pointer events, kept for the translation to hand to
  /// [ClickDebouncer] as the source of the data it derives from them.
  ///
  /// The browser fires each one just before the Touch event it is translated
  /// from, so the entry is always this gesture's.
  final Map<String, DomEvent> _withheldPointerEvents = <String, DomEvent>{};

  void _interceptNativePointerEvent(DomEvent event) {
    final pointerEvent = event as DomPointerEvent;
    if (pointerEvent.pointerType != 'touch') {
      return;
    }
    if (pointerEvent.type == 'pointerdown') {
      _withheldPointerEvents.clear();
    }
    _withheldPointerEvents[pointerEvent.type] = pointerEvent;
    if (pointerEvent.type == 'pointerdown' &&
        pointerEvent.target == _view.dom.rootElement &&
        EngineSemantics.instance.receiveGlobalEvent(event)) {
      // What PointerBinding's pointerdown handler does, which this interception
      // stops from running, under the semantics gate that wraps it there:
      // suppress the browser's focus handling and ask for the view's focus a
      // turn later.
      pointerEvent.preventDefault();
      Timer(Duration.zero, () {
        EnginePlatformDispatcher.instance.requestViewFocusChange(
          viewId: _view.viewId,
          state: ui.ViewFocusState.focused,
          direction: ui.ViewFocusDirection.undefined,
        );
      });
    }
    pointerEvent.stopImmediatePropagation();
  }

  void _translateTouchEvent(DomTouchEvent event, ui.PointerChange change) {
    // As in _translateRawUpdate, except that only a new contact is withheld: one
    // already reported as down has to be closed out, or the framework keeps
    // waiting for a finger that is gone.
    final bool accepted = EngineSemantics.instance.receiveGlobalEvent(event);
    if (!accepted && change == ui.PointerChange.down) {
      return;
    }
    final bool isDown = change == ui.PointerChange.down || change == ui.PointerChange.move;
    final double dpr = _view.devicePixelRatio;
    final Duration timeStamp = _durationFromMilliseconds(event.timeStamp!);
    for (final DomTouch touch in event.changedTouches) {
      final int device = touch.identifier!.toInt();
      if (change == ui.PointerChange.down) {
        if (_activeTouchIds.contains(device)) {
          continue;
        }
        _activeTouchIds.add(device);
        if (_activeTouchIds.length > 1) {
          _rawUpdatedContact = null;
        }
      } else if (!_activeTouchIds.contains(device)) {
        continue;
      } else if (change == ui.PointerChange.move) {
        if (device == _rawUpdatedContact) {
          // Already reported by `pointerrawupdate`, with less latency. Cleared
          // as it is consumed, so that a gesture whose raw updates stop coming
          // falls back to the next `touchmove`.
          _rawUpdatedContact = null;
          continue;
        }
      } else {
        _activeTouchIds.remove(device);
        _rawUpdatedContact = null;
      }
      final data = <ui.PointerData>[];
      _pointerDataConverter.convert(
        data,
        viewId: _view.viewId,
        change: change,
        timeStamp: timeStamp,
        device: device,
        // In full-page mode the host is position:fixed at (0,0), so clientX/Y
        // are already root-relative.
        physicalX: touch.clientX * dpr,
        physicalY: touch.clientY * dpr,
        buttons: isDown ? 1 : 0,
        pressure: isDown ? _fingerPressure : 0.0,
        pressureMax: 1.0,
      );
      // The withheld pointer event this data stands in for, so that the
      // debouncer sees the type and target it keys on. The Touch event is the
      // fallback for a phase the browser did not report as a pointer event, and
      // is inert to the debouncer.
      final DomEvent source = switch (change) {
        ui.PointerChange.down => _withheldPointerEvents['pointerdown'] ?? event,
        ui.PointerChange.up => _withheldPointerEvents['pointerup'] ?? event,
        ui.PointerChange.cancel => _withheldPointerEvents['pointercancel'] ?? event,
        _ => event,
      };
      PointerBinding.clickDebouncer.onPointerData(source, data);
    }
  }

  /// What a touch-type Pointer Event reports for a finger on hardware that
  /// cannot measure pressure.
  static const double _fingerPressure = 0.5;

  static Duration _durationFromMilliseconds(num milliseconds) {
    final int ms = milliseconds.toInt();
    final int micro = ((milliseconds - ms) * Duration.microsecondsPerMillisecond).toInt();
    return Duration(milliseconds: ms, microseconds: micro);
  }

  /// Cancels touches still down, so no phantom pointers outlive the translation.
  void _cancelActiveTouches() {
    if (_activeTouchIds.isEmpty) {
      return;
    }
    final data = <ui.PointerData>[];
    for (final int device in _activeTouchIds) {
      // `convert` defaults to a cancel, for which it substitutes the pointer's
      // last known location.
      _pointerDataConverter.convert(data, viewId: _view.viewId, device: device);
    }
    _activeTouchIds.clear();
    _rawUpdatedContact = null;
    // `flushAndSend` flushes first, so a pending `down` reaches the framework
    // before the cancel that closes it out.
    PointerBinding.clickDebouncer.flushAndSend(data);
  }
}

typedef _ListenerRegistration = ({DomEventTarget target, String type, DomEventListener listener});
