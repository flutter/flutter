// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'dom.dart';
import 'view_embedder/embedding_strategy/embedding_strategy.dart';
import 'window.dart';

/// Manages browser-driven scrolling for a Flutter view.
///
/// When enabled, the view's root element (`<flutter-view>`) becomes a real
/// scrollable DOM element. The browser handles wheel, touch, keyboard,
/// momentum, and scroll chaining natively. This controller listens for the
/// resulting `scroll` event and reports the new position to the framework
/// via [FlutterView.onBrowserScroll].
///
/// The framework communicates content extent via the dart:ui API on
/// [FlutterView].
class BrowserScrollController {
  BrowserScrollController(this._view);

  final EngineFlutterView _view;

  bool _enabled = false;
  bool get enabled => _enabled;

  JSFunction? _scrollListener;
  double? _lastProgrammaticScrollTop;

  /// Enables browser-driven scrolling for this view.
  void enable() {
    if (_enabled) {
      return;
    }

    final EmbeddingStrategy strategy = _view.embeddingStrategy;
    if (!strategy.supportsBrowserScrolling) {
      return;
    }

    _enabled = true;
    strategy.enableBrowserScrolling(_view.dom.rootElement);
    _attachScrollListener();
  }

  /// Disables browser-driven scrolling for this view.
  void disable() {
    if (!_enabled) {
      return;
    }

    _enabled = false;
    _detachScrollListener();
    _view.embeddingStrategy.disableBrowserScrolling(_view.dom.rootElement);
  }

  /// Updates the total scroll content height. Called when the framework
  /// reports a new content extent.
  void updateContentHeight(double height) {
    _view.embeddingStrategy.updateScrollContentHeight(height);
  }

  /// Instantly scrolls the root element to [offset].
  ///
  /// Notifies the framework directly so its [ScrollPosition.pixels] stays
  /// in sync. The DOM `scroll` event echo is suppressed via
  /// [_lastProgrammaticScrollTop] to avoid a duplicate notification.
  void scrollTo(double offset) {
    if (_enabled) {
      final DomElement root = _view.dom.rootElement;
      root.scrollTop = offset;
      final double newTop = root.scrollTop;
      _lastProgrammaticScrollTop = newTop;
      _sendScrollPositionToFramework(newTop);
    }
  }

  void smoothScrollTo(double offset) {
    if (_enabled) {
      _view.dom.rootElement.scrollTo(top: offset, behavior: 'smooth');
    }
  }

  /// Scrolls the root element by [delta] pixels.
  ///
  /// Calls [_sendScrollPositionToFramework] directly rather than relying on
  /// the DOM `scroll` event, so the framework sees the new position even
  /// though [_lastProgrammaticScrollTop] would otherwise suppress the echo.
  ///
  /// Used by the framework to forward inner-scrollable overscroll into the
  /// outer browser viewport.
  void scrollBy(double delta) {
    if (_enabled) {
      final DomElement root = _view.dom.rootElement;
      root.scrollTop = root.scrollTop + delta;
      final double newTop = root.scrollTop;
      _lastProgrammaticScrollTop = newTop;
      _sendScrollPositionToFramework(newTop);
    }
  }

  void _attachScrollListener() {
    final DomElement scrollTarget = _view.dom.rootElement;

    void onScroll() {
      final double scrollTop = scrollTarget.scrollTop;
      // Suppress echo when the framework just wrote scrollTop programmatically.
      if (_lastProgrammaticScrollTop != null &&
          (scrollTop - _lastProgrammaticScrollTop!).abs() < 1.0) {
        _lastProgrammaticScrollTop = null;
        return;
      }
      _lastProgrammaticScrollTop = null;
      _sendScrollPositionToFramework(scrollTop);
    }

    _scrollListener = onScroll.toJS;
    scrollTarget.addEventListener('scroll', _scrollListener);
  }

  void _detachScrollListener() {
    final JSFunction? listener = _scrollListener;
    if (listener != null) {
      _view.dom.rootElement.removeEventListener('scroll', listener);
      _scrollListener = null;
    }
  }

  void _sendScrollPositionToFramework(double scrollTop) {
    _view.onBrowserScroll?.call(scrollTop);
  }

  void dispose() {
    disable();
  }
}
