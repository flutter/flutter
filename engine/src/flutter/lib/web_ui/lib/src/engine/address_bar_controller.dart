// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'dom.dart';
import 'platform_dispatcher.dart';
import 'pointer_converter.dart';
import 'view_embedder/embedding_strategy/full_page_embedding_strategy.dart';
import 'window.dart';

typedef _ListenerRecord = ({
  DomEventTarget target,
  String type,
  DomEventListener listener,
  JSAny options,
});

/// Enables mobile browser address bar collapse for Flutter web apps.
///
/// Flutter web sets `touch-action: none` on `<body>`, preventing the
/// browser from detecting scrolls. This class sets `touch-action: pan-y`
/// and adds a spacer to make `<body>` scrollable, allowing the browser
/// to collapse the address bar on scroll.
///
/// ## Touch input switching
///
/// `touch-action: pan-y` causes the browser to fire `pointercancel`
/// during vertical scrolling, breaking [PointerBinding]'s gesture stream.
/// This class blocks touch-type Pointer Events at the capture phase and
/// handles finger input via Touch Events instead. Mouse and pen Pointer
/// Events pass through to [PointerBinding] unchanged.
///
/// ## Scroll position management
///
/// On iOS, a single scroll-snap target at the midpoint of a large spacer
/// prevents momentum scrolling while keeping scrollTop far from 0.
///
/// On Android, two scroll-snap targets (top and bottom) form a binary
/// state: the snap direction matches the user's scroll direction, which
/// is required because Chrome uses final scroll direction (not gesture
/// direction) for address bar detection. The top target is offset by 1px
/// from scrollTop=0 to prevent pull-to-refresh.
///
/// Only active for full-page embedding on mobile. On desktop or with a
/// custom host element, the constructor and [dispose] are no-ops.
///
/// See also:
///
///  * https://github.com/flutter/flutter/issues/69529
class AddressBarController {
  AddressBarController(this._view) : _pointerDataConverter = PointerDataConverter() {
    if (!_isSupported) {
      return;
    }

    domDocument.body!.style
      ..overflowY = 'auto'
      ..setProperty('touch-action', 'pan-y');

    _setupSpacer();
    _blockTouchPointerEvents();
    _setupTouchHandlers();
  }

  final EngineFlutterView _view;
  final PointerDataConverter _pointerDataConverter;

  static bool get _isIOs => ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs;
  static bool get _isAndroid => ui_web.browser.operatingSystem == ui_web.OperatingSystem.android;

  bool get _isSupported =>
      (_isIOs || _isAndroid) && _view.embeddingStrategy is FullPageEmbeddingStrategy;

  final Set<int> _activeTouchIds = <int>{};
  final List<_ListenerRecord> _listeners = [];

  DomElement? _spacerElement;

  void dispose() {
    if (!_isSupported) {
      return;
    }
    for (final _ListenerRecord r in _listeners) {
      r.target.removeEventListener(r.type, r.listener, r.options);
    }
    _listeners.clear();
    _spacerElement?.remove();
    domDocument.body!.style
      ..overflowY = 'hidden'
      ..setProperty('touch-action', 'none');
    domDocument.documentElement!.style
      ..setProperty('scroll-snap-type', '')
      ..setProperty('scrollbar-width', '');
  }

  void _setupSpacer() {
    domDocument.documentElement!.style
      ..setProperty('scroll-snap-type', 'y mandatory')
      ..setProperty('scrollbar-width', 'none');

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
      // Two snap targets: snap direction matches user's scroll direction,
      // which Chrome requires for correct address bar detection.
      // Top snap at 1px prevents scrollTop=0 (pull-to-refresh).
      // collapseMargin keeps the bottom snap reachable after the address
      // bar collapses and the viewport grows (~80px).
      const snapDistance = 100;
      const collapseMargin = 100;
      final int viewportHeight = domWindow.innerHeight!.toInt();
      spacer.style.height = '${viewportHeight + snapDistance + 1 + collapseMargin}px';
      spacer.append(_createSnapTarget(1));
      spacer.append(_createSnapTarget(snapDistance + 1));
    } else if (_isIOs) {
      // Single snap target at midpoint prevents momentum scrolling
      // and keeps scrollTop far from 0 (no pull-to-refresh).
      const spacerHeight = 10000;
      spacer.style.height = '${spacerHeight}px';
      spacer.append(_createSnapTarget(spacerHeight ~/ 2));
    }

    domDocument.documentElement!.append(spacer);
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

  /// Blocks touch-type Pointer Events from reaching [PointerBinding].
  ///
  /// Only `pointerType === 'touch'` is blocked. Mouse and pen events pass
  /// through to [PointerBinding] unchanged, preserving pressure, tilt, and
  /// other Pointer Event features.
  void _blockTouchPointerEvents() {
    final DomElement root = _view.dom.rootElement;
    const pointerEventTypes = <String>[
      'pointerdown',
      'pointermove',
      'pointerup',
      'pointercancel',
      'pointerleave',
    ];
    final JSAny options = DomEventListenerOptions(capture: true);
    for (final type in pointerEventTypes) {
      final DomEventListener listener = createDomEventListener((DomEvent event) {
        final pe = event as DomPointerEvent;
        if (pe.pointerType == 'touch') {
          event.stopImmediatePropagation();
        }
      });
      root.addEventListener(type, listener, options);
      _listeners.add((target: root, type: type, listener: listener, options: options));
    }
  }

  void _setupTouchHandlers() {
    final DomElement root = _view.dom.rootElement;
    final JSAny options = DomEventListenerOptions(passive: true);

    void listen(String type, DartDomEventListener handler) {
      final DomEventListener listener = createDomEventListener(handler);
      root.addEventListener(type, listener, options);
      _listeners.add((target: root, type: type, listener: listener, options: options));
    }

    listen('touchstart', (DomEvent event) {
      final te = event as DomTouchEvent;
      final num ts = te.timeStamp!;
      for (final DomTouch touch in te.changedTouches) {
        final int id = touch.identifier!.toInt();
        _activeTouchIds.add(id);
        final ui.Offset offset = _touchOffset(touch);
        _sendPointerData(ui.PointerChange.down, ts, id, offset, 1);
      }
    });

    listen('touchmove', (DomEvent event) {
      final te = event as DomTouchEvent;
      final num ts = te.timeStamp!;
      for (final DomTouch touch in te.changedTouches) {
        final int id = touch.identifier!.toInt();
        if (!_activeTouchIds.contains(id)) {
          continue;
        }
        final ui.Offset offset = _touchOffset(touch);
        _sendPointerData(ui.PointerChange.move, ts, id, offset, 1);
      }
    });

    listen('touchend', (DomEvent event) {
      final te = event as DomTouchEvent;
      final num ts = te.timeStamp!;
      for (final DomTouch touch in te.changedTouches) {
        final int id = touch.identifier!.toInt();
        if (!_activeTouchIds.remove(id)) {
          continue;
        }
        final ui.Offset offset = _touchOffset(touch);
        _sendPointerData(ui.PointerChange.up, ts, id, offset, 0);
      }
    });

    listen('touchcancel', (DomEvent event) {
      final te = event as DomTouchEvent;
      final num ts = te.timeStamp!;
      for (final DomTouch touch in te.changedTouches) {
        final int id = touch.identifier!.toInt();
        if (!_activeTouchIds.remove(id)) {
          continue;
        }
        final ui.Offset offset = _touchOffset(touch);
        _sendPointerData(ui.PointerChange.cancel, ts, id, offset, 0);
      }
    });
  }

  ui.Offset _touchOffset(DomTouch touch) {
    final DomRect rect = _view.dom.rootElement.getBoundingClientRect();
    return ui.Offset(touch.clientX - rect.x, touch.clientY - rect.y);
  }

  void _sendPointerData(
    ui.PointerChange change,
    num eventTimeStamp,
    int device,
    ui.Offset offset,
    int buttons,
  ) {
    final int ms = eventTimeStamp.toInt();
    final timeStamp = Duration(
      milliseconds: ms,
      microseconds: ((eventTimeStamp - ms) * Duration.microsecondsPerMillisecond).toInt(),
    );
    final data = <ui.PointerData>[];
    final double dpr = _view.devicePixelRatio;
    _pointerDataConverter.convert(
      data,
      viewId: _view.viewId,
      change: change,
      timeStamp: timeStamp,
      signalKind: ui.PointerSignalKind.none,
      device: device,
      physicalX: offset.dx * dpr,
      physicalY: offset.dy * dpr,
      buttons: buttons,
      pressure: buttons > 0 ? 1.0 : 0.0,
      pressureMax: 1.0,
    );
    EnginePlatformDispatcher.instance.invokeOnPointerDataPacket(ui.PointerDataPacket(data: data));
  }
}
