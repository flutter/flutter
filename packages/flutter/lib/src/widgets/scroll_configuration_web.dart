// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Default value for browser scrolling enabled on web.
const bool _kDefaultBrowserScrollingEnabled = false;

/// Public getter for the default browser scrolling enabled value.
bool get kDefaultBrowserScrollingEnabled => _kDefaultBrowserScrollingEnabled;

/// Creates a browser scroll strategy for the given view ID.
ExternalScroller createBrowserScrollStrategy(int viewId) {
  return JsViewScroller(viewId);
}

/// Callback for visible rect changes.
typedef RectCallback = void Function(ui.Rect);

/// Interface for external scrollers that control scrolling via the browser DOM.
abstract class ExternalScroller {
  /// The current scroll position from the top.
  double get scrollTop;

  /// Computes the currently visible rectangle.
  ui.Rect computeVisibleRect();

  /// Sets up the scroller (creates DOM elements, etc.).
  void setup();

  /// Adds a listener for scroll events.
  void addScrollListener(ui.VoidCallback callback);

  /// Adds a listener for visible rect changes.
  void addVisibleRectListener(RectCallback callback);

  /// Updates the total content height.
  void updateHeight(double height);

  /// Disposes of the scroller and cleans up resources.
  void dispose();
}

/// Implementation of [ExternalScroller] that uses JavaScript/DOM APIs.
class JsViewScroller implements ExternalScroller {
  /// Creates a JS view scroller for the given view ID.
  JsViewScroller(int viewId)
      : _hostElement = ui_web.views.getHostElement(viewId) as web.HTMLElement;

  final web.HTMLElement _hostElement;
  late final web.HTMLElement _placeholderElement;
  final web.EventTarget _scrollTarget = web.window;
  late final JSFunction _jsScrollListener = _scrollListener.toJS;

  final List<ui.VoidCallback> _scrollListeners = <ui.VoidCallback>[];
  final List<RectCallback> _visibleRectListeners = <RectCallback>[];
  web.IntersectionObserver? _observer;

  ui.Rect _lastVisibleRect = ui.Rect.zero;

  @override
  ui.Rect computeVisibleRect() {
    final web.DOMRect placeholderRect = _placeholderElement.getBoundingClientRect();
    final double windowWidth = web.window.innerWidth.toDouble();
    final double windowHeight = web.window.innerHeight.toDouble();
    return _toRect(placeholderRect).intersect(
      ui.Rect.fromLTWH(0, 0, windowWidth, windowHeight),
    );
  }

  @override
  void setup() {
    _placeholderElement = _hostElement.cloneNode() as web.HTMLElement;
    _hostElement.parentElement!.insertBefore(_placeholderElement, _hostElement);

    // Ensure <html> allows scrolling (fix for full-page embedding mode)
    final web.HTMLElement htmlElement = web.document.documentElement! as web.HTMLElement;
    htmlElement.style.overflow = 'auto';

    // Ensure placeholder is scrollable
    _placeholderElement.style
      ..position = 'static'
      ..overflow = 'visible';

    // Set Flutter host to fixed position
    _hostElement.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..bottom = '0';

    if (kDebugMode) {
      print('[BrowserScroller] Setup complete: placeholder created, host set to fixed');
    }
  }

  @override
  double get scrollTop {
    if (_scrollTarget.isA<web.Window>()) {
      return (_scrollTarget as web.Window).scrollY - _placeholderElement.offsetTop;
    }
    return (_scrollTarget as web.HTMLElement).scrollTop - _placeholderElement.offsetTop;
  }

  @override
  void addVisibleRectListener(RectCallback callback) {
    if (_visibleRectListeners.isEmpty) {
      addScrollListener(_visibleRectListener);
      _addIntersectionObserver(_visibleRectListener);
    }
    _visibleRectListeners.add(callback);
  }

  void _visibleRectListener() {
    final ui.Rect newVisibleRect = computeVisibleRect();

    if (_lastVisibleRect != newVisibleRect) {
      _lastVisibleRect = newVisibleRect;
      for (final RectCallback listener in _visibleRectListeners) {
        listener(newVisibleRect);
      }
    }
  }

  void _addIntersectionObserver(ui.VoidCallback callback) {
    _observer = web.IntersectionObserver(
      (JSArray<web.IntersectionObserverEntry> entries, JSAny observer) {
        for (final web.IntersectionObserverEntry entry in entries.toDart) {
          if (entry.isIntersecting) {
            callback();
          }
        }
      }.toJS,
      web.IntersectionObserverInit(
        threshold: <JSNumber>[for (int i = 0; i <= 100; i++) (i / 100).toJS].toJS,
      ),
    );

    _observer!.observe(_placeholderElement);
  }

  @override
  void addScrollListener(ui.VoidCallback callback) {
    if (_scrollListeners.isEmpty) {
      _scrollTarget.addEventListener('scroll', _jsScrollListener);
    }
    _scrollListeners.add(callback);
  }

  void _scrollListener() {
    for (final ui.VoidCallback listener in _scrollListeners) {
      listener();
    }
  }

  @override
  void updateHeight(double height) {
    _placeholderElement.style.height = '${height}px';
  }

  @override
  void dispose() {
    _observer?.disconnect();
    if (_scrollListeners.isNotEmpty) {
      _scrollTarget.removeEventListener('scroll', _jsScrollListener);
    }
  }

  ui.Rect _toRect(web.DOMRect domRect) {
    return ui.Rect.fromLTWH(
      domRect.left.toDouble(),
      domRect.top.toDouble(),
      domRect.width.toDouble(),
      domRect.height.toDouble(),
    );
  }
}

