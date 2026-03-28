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

/// Enables iOS browser address bar collapse for Flutter web apps.
///
/// The browser collapses the address bar only when it detects a
/// user-initiated scroll, which requires `touch-action` to not be `none`.
/// However, changing `touch-action` causes the browser to fire
/// `pointercancel` during vertical scroll, breaking [PointerBinding]'s
/// gesture stream.
///
/// This class works around the issue by blocking touch-type Pointer Events
/// and handling finger input via Touch Events instead. Touch Events are
/// independent of Pointer Events and continue after `pointercancel`.
/// Mouse and pen Pointer Events are not blocked — [PointerBinding] handles
/// them normally.
///
/// Only active for full-page embedding on iOS. On other platforms or with
/// a custom host element, the constructor is a no-op.
///
/// See https://github.com/flutter/flutter/issues/69529
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

  static const int spacerHeight = 10000;

  final EngineFlutterView _view;
  final PointerDataConverter _pointerDataConverter;

  bool get _isSupported =>
      ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs &&
      _view.embeddingStrategy is FullPageEmbeddingStrategy;

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

  /// Appends a tall invisible element under `<html>` to provide scroll room.
  ///
  /// `scroll-snap-type: y mandatory` on `<html>` with a snap point at the
  /// center prevents iOS Safari from momentum-scrolling, which would block
  /// touch event delivery until momentum stops.
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
      ..height = '${spacerHeight}px'
      ..pointerEvents = 'none'
      ..opacity = '0';
    _spacerElement = spacer;
    domDocument.documentElement!.append(spacer);

    final DomElement snapTarget = createDomElement('flt-scroll-snap-target');
    snapTarget.style
      ..position = 'absolute'
      ..top = '${spacerHeight ~/ 2}px'
      ..left = '0'
      ..width = '1px'
      ..height = '1px'
      ..setProperty('scroll-snap-align', 'start');
    spacer.append(snapTarget);
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
