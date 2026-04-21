// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:meta/meta.dart';

import 'dom.dart';
import 'view_embedder/embedding_strategy/embedding_strategy.dart';
import 'window.dart';

/// Manages browser-driven scrolling for a Flutter view.
///
/// When enabled, the outermost scrollable in a Flutter view delegates to the
/// browser. The host element becomes a real scrollable DOM element, and the
/// browser handles scroll physics, momentum, and scroll chaining natively.
///
/// The framework communicates content extent via the dart:ui API on
/// [FlutterView], and the engine sends scroll position updates back to the
/// framework via the [FlutterView.onBrowserScroll] callback.
class BrowserScrollController {
  BrowserScrollController(this._view);

  final EngineFlutterView _view;

  bool _enabled = false;
  bool get enabled => _enabled;

  JSFunction? _scrollListener;
  JSFunction? _touchStartBlocker;
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
    _attachTouchStartBlocker();
    _attachPlatformViewTouchChaining();
  }

  /// Disables browser-driven scrolling for this view.
  void disable() {
    if (!_enabled) {
      return;
    }

    _enabled = false;
    _detachScrollListener();
    _detachTouchStartBlocker();
    _detachPlatformViewTouchChaining();
    _view.embeddingStrategy.disableBrowserScrolling(_view.dom.rootElement);
  }

  /// Updates the total scroll content height. Called when the framework
  /// reports a new content extent.
  void updateContentHeight(double height) {
    _view.embeddingStrategy.updateScrollContentHeight(height);
  }

  void scrollTo(double offset) {
    if (_enabled) {
      if (_pvTouchActive) {
        return;
      }
      _lastProgrammaticScrollTop = offset;
      _view.dom.rootElement.scrollTop = offset;
    }
  }

  void smoothScrollTo(double offset) {
    if (_enabled) {
      if (_pvTouchActive) {
        return;
      }
      _view.dom.rootElement.scrollTo(top: offset, behavior: 'smooth');
    }
  }

  /// Scrolls the root element by [delta] pixels.
  ///
  /// Does not check [_pvTouchActive] because the platform-view touch
  /// chaining handler calls this method during an active touch to forward
  /// boundary overflow to the outer flutter-view scroll.
  ///
  /// Calls [_sendScrollPositionToFramework] directly rather than relying on
  /// the DOM `scroll` event: after writing [_lastProgrammaticScrollTop], the
  /// onScroll listener would suppress the subsequent scroll event as a
  /// programmatic echo, and the framework would never see the new position.
  void scrollBy(double delta) {
    if (_enabled) {
      final DomElement root = _view.dom.rootElement;
      root.scrollTop = root.scrollTop + delta;
      final double newTop = root.scrollTop;
      _lastProgrammaticScrollTop = newTop;
      _sendScrollPositionToFramework(newTop);
    }
  }

  // ---- Touch start blocker ----
  //
  // Prevents the browser from initiating native touch scrolling on
  // <flutter-view>. This must be a non-passive touchstart listener so
  // that preventDefault() actually works. The pointerdown handler's
  // preventDefault() alone is not sufficient because modern browsers
  // register pointer event listeners as passive by default.

  void _attachTouchStartBlocker() {
    void onTouchStart(DomEvent event) {
      event.preventDefault();
    }

    _touchStartBlocker = onTouchStart.toJS;
    _view.dom.rootElement.addEventListener(
      'touchstart',
      _touchStartBlocker,
      <String, Object>{'passive': false}.toJSAnyDeep,
    );
  }

  void _detachTouchStartBlocker() {
    final JSFunction? blocker = _touchStartBlocker;
    if (blocker != null) {
      _view.dom.rootElement.removeEventListener('touchstart', blocker);
      _touchStartBlocker = null;
    }
  }

  // ---- Outer scroll listener ----

  void _attachScrollListener() {
    final DomElement scrollTarget = _view.dom.rootElement;

    void onScroll() {
      final double scrollTop = scrollTarget.scrollTop;
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

  // ---- Platform view touch scroll chaining ----
  //
  // Browser scroll chaining from a scrollable native element inside a
  // platform view to <flutter-view> doesn't work on touch devices because
  // of the shadow DOM + position:sticky structure. We work around this by
  // listening for touch events on the platformViewsHost and programmatically
  // scrolling <flutter-view> when an inner scrollable hits its boundary.

  DomEventListener? _pvTouchStartListener;
  JSFunction? _pvTouchMoveListener;
  DomEventListener? _pvTouchEndListener;

  double? _touchStartY;
  DomElement? _activeScrollable;
  bool _pvTouchActive = false;

  /// Whether a platform-view touch gesture is currently active.
  ///
  /// Used by [EngineFlutterView.browserScrollBy] to skip framework-initiated
  /// scroll-by calls during a touch, since the touch chaining handler already
  /// forwards boundary overflow via [scrollBy] directly.
  bool get pvTouchActive => _pvTouchActive;

  void _attachPlatformViewTouchChaining() {
    final DomElement pvHost = _view.dom.platformViewsHost;
    final DomElement root = _view.dom.rootElement;

    bool isPlatformViewTarget(DomEvent event) {
      final DomEventTarget? target = event.target;
      if (target != null && target.isA<DomElement>()) {
        return pvHost.contains(target as DomElement);
      }
      return false;
    }

    _pvTouchStartListener = createDomEventListener((DomEvent event) {
      if (!isPlatformViewTarget(event)) {
        _pvTouchActive = false;
        return;
      }
      _pvTouchActive = true;
      final te = event as DomTouchEvent;
      final Iterable<DomTouch> touches = te.touches;
      if (touches.isEmpty) {
        return;
      }
      _touchStartY = touches.first.clientY;
      final DomEventTarget? target = event.target;
      if (target != null && target.isA<DomElement>()) {
        final el = target as DomElement;
        _activeScrollable = _findScrollableAncestor(el);
        if (_activeScrollable == null) {
          // Scope the descendant walk to the specific platform view the
          // user touched. Walking all of pvHost would return a scrollable
          // from a different platform view and scroll the wrong content.
          final DomElement? pv = containingPlatformView(el, pvHost);
          if (pv != null) {
            _activeScrollable = _findScrollableDescendant(pv);
          }
        }
      }
    });

    void onTouchMove(DomEvent event) {
      if (!isPlatformViewTarget(event)) {
        return;
      }
      final te = event as DomTouchEvent;
      if (_touchStartY == null) {
        return;
      }
      final Iterable<DomTouch> touches = te.touches;
      if (touches.isEmpty) {
        return;
      }

      final double currentY = touches.first.clientY;
      final double deltaY = _touchStartY! - currentY;
      _touchStartY = currentY;

      event.preventDefault();

      if (_activeScrollable != null) {
        final DomElement el = _activeScrollable!;
        final double scrollTop = el.scrollTop;
        final double maxScroll = el.scrollHeight - el.clientHeight;
        final bool atTop = scrollTop <= 0 && deltaY < 0;
        final bool atBottom = scrollTop >= maxScroll - 1 && deltaY > 0;

        if (atTop || atBottom) {
          scrollBy(deltaY);
        } else {
          el.scrollTop = scrollTop + deltaY;
        }
      } else {
        scrollBy(deltaY);
      }
    }

    _pvTouchMoveListener = onTouchMove.toJS;
    root.addEventListener(
      'touchmove',
      _pvTouchMoveListener,
      <String, Object>{'passive': false, 'capture': true}.toJSAnyDeep,
    );

    _pvTouchEndListener = createDomEventListener((DomEvent event) {
      _pvTouchActive = false;
      _touchStartY = null;
      _activeScrollable = null;
    });

    root.addEventListener('touchstart', _pvTouchStartListener, true.toJS);
    root.addEventListener('touchend', _pvTouchEndListener, true.toJS);
    root.addEventListener('touchcancel', _pvTouchEndListener, true.toJS);
  }

  void _detachPlatformViewTouchChaining() {
    final DomElement root = _view.dom.rootElement;
    if (_pvTouchStartListener != null) {
      // Per DOM spec, removeEventListener matches on {type, listener, capture}.
      // These listeners were registered with capture=true, so the remove call
      // must pass capture=true too; otherwise it silently no-ops.
      root.removeEventListener('touchstart', _pvTouchStartListener, true.toJS);
      root.removeEventListener('touchmove', _pvTouchMoveListener, true.toJS);
      root.removeEventListener('touchend', _pvTouchEndListener, true.toJS);
      root.removeEventListener('touchcancel', _pvTouchEndListener, true.toJS);
      _pvTouchStartListener = null;
      _pvTouchMoveListener = null;
      _pvTouchEndListener = null;
    }
    _pvTouchActive = false;
    _touchStartY = null;
    _activeScrollable = null;
  }

  /// Finds a platform view element at the given screen coordinates.
  ///
  /// Used when the wheel event target is a semantics node overlaying a
  /// platform view. Checks each platform view's bounding rect to find
  /// which one, if any, contains the given point.
  DomElement? findPlatformViewAtPoint(num clientX, num clientY) {
    final DomElement pvHost = _view.dom.platformViewsHost;
    for (final DomElement child in pvHost.children) {
      final DomRect rect = child.getBoundingClientRect();
      if (rect.width > 0 &&
          rect.height > 0 &&
          clientX >= rect.left &&
          clientX <= rect.right &&
          clientY >= rect.top &&
          clientY <= rect.bottom) {
        return child;
      }
    }
    return null;
  }

  /// Handles a wheel event targeting a platform view element.
  ///
  /// Scrolls the inner scrollable element within the platform view. If the
  /// inner scrollable is at its boundary, forwards the remaining delta to
  /// the outer <flutter-view> scroll.
  void handlePlatformViewWheel(DomElement target, double deltaY) {
    DomElement? scrollable = _findScrollableAncestor(target);
    scrollable ??= _findScrollableDescendant(target);
    if (scrollable == null) {
      scrollBy(deltaY);
      return;
    }

    final double scrollTop = scrollable.scrollTop;
    final double maxScroll = scrollable.scrollHeight - scrollable.clientHeight;
    final bool atTop = scrollTop <= 0 && deltaY < 0;
    final bool atBottom = scrollTop >= maxScroll - 1 && deltaY > 0;

    if (atTop || atBottom) {
      scrollBy(deltaY);
    } else {
      scrollable.scrollTop = scrollTop + deltaY;
    }
  }

  /// Returns the direct child of [pvHost] that contains [target], or null
  /// if [target] is not inside any platform view.
  ///
  /// Used by the touch-start path to scope the scrollable-descendant search
  /// to a single platform view so a touch on one platform view cannot
  /// return a scrollable that lives in a different platform view.
  @visibleForTesting
  DomElement? containingPlatformView(DomElement target, DomElement pvHost) {
    DomElement? current = target;
    while (current != null && current.parentElement != pvHost) {
      current = current.parentElement;
    }
    return current;
  }

  /// Walks down from [element] to find the first descendant with scrollable
  /// overflow and content that actually overflows.
  DomElement? _findScrollableDescendant(DomElement element) {
    for (final DomElement child in element.children) {
      if (child.scrollHeight > child.clientHeight) {
        final DomCSSStyleDeclaration style = domWindow.getComputedStyle(child);
        final String overflowY = style.overflowY;
        if (overflowY == 'auto' || overflowY == 'scroll') {
          return child;
        }
      }
      final DomElement? found = _findScrollableDescendant(child);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Walks up from [element] to find the nearest ancestor with scrollable
  /// overflow and content that actually overflows.
  DomElement? _findScrollableAncestor(DomElement element) {
    DomElement? current = element;
    final DomElement root = _view.dom.rootElement;
    while (current != null && current != root) {
      if (current.scrollHeight > current.clientHeight) {
        final DomCSSStyleDeclaration style = domWindow.getComputedStyle(current);
        final String overflowY = style.overflowY;
        if (overflowY == 'auto' || overflowY == 'scroll') {
          return current;
        }
      }
      current = current.parentElement;
    }
    return null;
  }

  void dispose() {
    disable();
  }
}
