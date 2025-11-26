// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Web-specific scroll configuration and browser scrolling integration.
///
/// This file provides automatic browser-driven scrolling for Flutter web apps,
/// solving nested scrolling issues and providing native browser scrolling behavior.
library;

import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scrollable.dart';
import 'view.dart';

/// Whether browser scrolling is enabled by default for Flutter web apps.
///
/// Defaults to false (opt-in). Set to true via [setBrowserScrollingDefault]
/// to enable browser scrolling by default for all scrollables.
bool _kDefaultBrowserScrollingEnabled = false;

/// Gets the current default browser scrolling setting.
///
/// Returns true if browser scrolling is enabled by default.
bool get kDefaultBrowserScrollingEnabled => _kDefaultBrowserScrollingEnabled;

/// Sets the default browser scrolling behavior for all scrollables.
///
/// When enabled, Flutter will use native browser scrolling on web by default
/// (unless explicitly disabled with browserScrolling: false), which provides:
/// - Native touch and wheel scrolling behavior
/// - Proper nested scrolling disambiguation
/// - No iframe scroll blocking
///
/// Defaults to false. Set to true to opt-in all scrollables to browser scrolling.
void setBrowserScrollingDefault(bool enabled) {
  _kDefaultBrowserScrollingEnabled = enabled;
}

/// Interface for external scrollers that control scrolling via the browser DOM.
///
/// This is used internally by [BrowserScrollStrategy] to create and manage
/// a placeholder DOM element that the browser scrolls, while Flutter renders
/// at the appropriate scroll offset.
abstract class ExternalScroller {
  /// Sets up the external scroller (creates placeholder DOM, sets styles).
  void setup();

  /// Computes the currently visible rectangle based on browser scroll position.
  ui.Rect computeVisibleRect();

  /// Adds a listener for when the visible rect changes (browser scrolls).
  void addVisibleRectListener(VoidCallback listener);

  /// Removes a previously added visible rect listener.
  void removeVisibleRectListener(VoidCallback listener);

  /// Adds a listener for when the browser scroll event fires.
  void addScrollListener(VoidCallback listener);

  /// Removes a previously added scroll listener.
  void removeScrollListener(VoidCallback listener);

  /// Updates the height of the scrollable content.
  void updateHeight(double height);

  /// Enables boundary detection for nested scrolling.
  /// 
  /// When enabled, touch events are conditionally prevented based on scroll position.
  /// This allows parent scrollables to receive events when this scrollable is at its boundaries.
  void enableBoundaryDetection(ScrollController controller);

  /// Disables boundary detection.
  void disableBoundaryDetection();

  /// Cleans up resources.
  void dispose();
}

/// Implementation of [ExternalScroller] that uses JavaScript/DOM APIs.
///
/// This creates a placeholder `<body>` element with the correct height,
/// while setting the actual Flutter view to `position: fixed`. The browser
/// scrolls the placeholder, and Flutter renders based on `window.scrollY`.
class JsViewScroller implements ExternalScroller {
  JsViewScroller(this.viewId);

  final int viewId;
  late final web.HTMLElement _hostElement;
  late final web.HTMLElement _placeholderElement;
  final List<VoidCallback> _visibleRectListeners = <VoidCallback>[];
  final List<VoidCallback> _scrollListeners = <VoidCallback>[];
  late final web.EventListener _jsScrollListener;
  web.ResizeObserver? _observer;
  
  // Boundary detection state
  ScrollController? _boundaryDetectionController;
  web.EventListener? _touchStartListener;
  web.EventListener? _touchMoveListener;
  web.EventListener? _touchEndListener;
  web.EventListener? _touchCancelListener;
  double? _touchStartY;

  @override
  void setup() {
    _hostElement = ui_web.views.getHostElement(viewId) as web.HTMLElement;

    // Create placeholder element (a clone of the host that will be scrollable)
    _placeholderElement = _hostElement.cloneNode() as web.HTMLElement;
    _hostElement.parentElement!.insertBefore(_placeholderElement, _hostElement);

    // Set host element to fixed position (doesn't scroll with browser)
    _hostElement.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..bottom = '0';

    // Ensure HTML element allows scrolling
    (web.document.documentElement as web.HTMLElement).style
      ..overflow = 'auto'  // Allow scrolling on <html>
      ..height = 'auto'
      ..margin = '0'
      ..padding = '0';

    // Set placeholder to static positioning and visible overflow
    (_hostElement.parentElement! as web.HTMLElement).style
      ..position = 'static'
      ..overflow = 'visible';

    if (kDebugMode) {
      print('[BrowserScroller] Setup complete: placeholder created, host set to fixed');
    }
  }

  @override
  ui.Rect computeVisibleRect() {
    final double scrollTop = web.window.scrollY;
    final double windowHeight = web.window.innerHeight.toDouble();
    return ui.Rect.fromLTWH(0, scrollTop, web.window.innerWidth.toDouble(), windowHeight);
  }

  @override
  void addVisibleRectListener(VoidCallback listener) {
    if (_visibleRectListeners.isEmpty) {
      final int viewId = this.viewId;
      _observer = web.ResizeObserver((JSArray<JSObject> entries, JSObject observer) {
        for (final VoidCallback listener in _visibleRectListeners) {
          listener();
        }
      }.toJS);
      final web.Element? hostElement = ui_web.views.getHostElement(viewId) as web.Element?;
      if (hostElement != null) {
        _observer!.observe(hostElement);
      }
    }
    _visibleRectListeners.add(listener);
  }

  @override
  void removeVisibleRectListener(VoidCallback listener) {
    _visibleRectListeners.remove(listener);
    if (_visibleRectListeners.isEmpty) {
      _observer?.disconnect();
      _observer = null;
    }
  }

  web.EventTarget get _scrollTarget => web.window;

  @override
  void addScrollListener(VoidCallback listener) {
    if (_scrollListeners.isEmpty) {
      _jsScrollListener = (web.Event event) {
        for (final VoidCallback listener in _scrollListeners) {
          listener();
        }
      }.toJS;
      _scrollTarget.addEventListener('scroll', _jsScrollListener);
    }
    _scrollListeners.add(listener);
  }

  @override
  void removeScrollListener(VoidCallback listener) {
    _scrollListeners.remove(listener);
    if (_scrollListeners.isEmpty) {
      _scrollTarget.removeEventListener('scroll', _jsScrollListener);
    }
  }

  @override
  void updateHeight(double height) {
    _placeholderElement.style.height = '${math.max(height, web.window.innerHeight.toDouble())}px';
    if (kDebugMode) {
      print('[BrowserScroller] Updated height: ${height}px');
    }
  }

  @override
  void enableBoundaryDetection(ScrollController controller) {
    _boundaryDetectionController = controller;
    
    // Add touch event listeners to the host element for boundary detection
    _touchStartListener = (web.TouchEvent event) {
      if (event.touches.length > 0) {
        _touchStartY = event.touches.item(0)!.clientY.toDouble();
      }
    }.toJS;
    _hostElement.addEventListener('touchstart', _touchStartListener!, web.AddEventListenerOptions(passive: true));
    
    _touchMoveListener = (web.TouchEvent event) {
      final scrollController = _boundaryDetectionController;
      
      // If no scroll controller, always block (defensive)
      if (scrollController == null || !scrollController.hasClients || event.touches.length == 0) {
        event.preventDefault();
        return;
      }
      
      final currentY = event.touches.item(0)!.clientY.toDouble();
      final deltaY = _touchStartY != null ? currentY - _touchStartY! : 0.0;
      final position = scrollController.position;
      
      // Check if we're at boundaries and trying to scroll beyond
      final isAtTop = position.pixels <= position.minScrollExtent;
      final isAtBottom = position.pixels >= position.maxScrollExtent;
      final isScrollingUp = deltaY > 0; // Positive deltaY means finger moving down = scrolling up
      final isScrollingDown = deltaY < 0; // Negative deltaY means finger moving up = scrolling down
      
      // Allow event to bubble to parent if:
      // - At top and scrolling up, OR
      // - At bottom and scrolling down
      final shouldBubble = (isAtTop && isScrollingUp) || (isAtBottom && isScrollingDown);
      
      if (!shouldBubble) {
        event.preventDefault(); // Block browser scrolling
        if (kDebugMode) {
          print('[BrowserScroller] Blocked touch event (scrollable can scroll)');
        }
      } else {
        // Allow event to bubble to parent
        if (kDebugMode) {
          print('[BrowserScroller] Allowing touch event to bubble (at boundary)');
        }
      }
    }.toJS;
    _hostElement.addEventListener('touchmove', _touchMoveListener!, web.AddEventListenerOptions(passive: false)); // Must be non-passive to call preventDefault
    
    _touchEndListener = (web.TouchEvent event) {
      _touchStartY = null;
    }.toJS;
    _hostElement.addEventListener('touchend', _touchEndListener!, web.AddEventListenerOptions(passive: true));
    
    _touchCancelListener = (web.TouchEvent event) {
      _touchStartY = null;
    }.toJS;
    _hostElement.addEventListener('touchcancel', _touchCancelListener!, web.AddEventListenerOptions(passive: true));
    
    if (kDebugMode) {
      print('[BrowserScroller] Boundary detection enabled');
    }
  }

  @override
  void disableBoundaryDetection() {
    if (_touchStartListener != null) {
      _hostElement.removeEventListener('touchstart', _touchStartListener!);
      _touchStartListener = null;
    }
    if (_touchMoveListener != null) {
      _hostElement.removeEventListener('touchmove', _touchMoveListener!);
      _touchMoveListener = null;
    }
    if (_touchEndListener != null) {
      _hostElement.removeEventListener('touchend', _touchEndListener!);
      _touchEndListener = null;
    }
    if (_touchCancelListener != null) {
      _hostElement.removeEventListener('touchcancel', _touchCancelListener!);
      _touchCancelListener = null;
    }
    _boundaryDetectionController = null;
    _touchStartY = null;
    
    if (kDebugMode) {
      print('[BrowserScroller] Boundary detection disabled');
    }
  }

  @override
  void dispose() {
    disableBoundaryDetection();
    _observer?.disconnect();
    if (_scrollListeners.isNotEmpty) {
      _scrollTarget.removeEventListener('scroll', _jsScrollListener);
    }
  }
}

/// A scroll strategy that uses native browser scrolling instead of canvas-based scrolling.
///
/// This strategy creates a placeholder DOM element that the browser scrolls,
/// while Flutter renders at the current scroll offset. This provides:
/// - Native touch and wheel scrolling behavior
/// - No iframe scroll blocking
/// - Proper momentum scrolling
/// - Better accessibility
///
/// This is automatically used on web when browser scrolling is enabled.
class BrowserScrollStrategy {
  BrowserScrollStrategy({
    required this.scrollController,
    required this.externalScroller,
  });

  final ScrollController scrollController;
  final ExternalScroller externalScroller;

  late ui.Rect _visibleRect;
  bool _isInitialized = false;

  /// Initializes the browser scroll strategy.
  void initialize() {
    if (_isInitialized) {
      return;
    }

    externalScroller.setup();

    _syncVisibleRect();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScrollPosition();
      _syncContentHeight();
    });

    _isInitialized = true;
  }

  void _syncVisibleRect() {
    _visibleRect = externalScroller.computeVisibleRect();
    externalScroller.addVisibleRectListener(_updateVisibleRect);
  }

  void _updateVisibleRect() {
    final ui.Rect newVisibleRect = externalScroller.computeVisibleRect();
    if (_visibleRect != newVisibleRect) {
      _visibleRect = newVisibleRect;
    }
  }

  void _syncScrollPosition() {
    externalScroller.addScrollListener(() {
      final ui.Rect visibleRect = externalScroller.computeVisibleRect();
      if (scrollController.hasClients) {
        final ScrollPosition position = scrollController.position;
        if ((position.pixels - visibleRect.top).abs() > 1.0) {
          position.jumpTo(visibleRect.top);
        }
      }
    });
  }

  void _syncContentHeight() {
    if (scrollController.hasClients) {
      scrollController.position.addListener(_handleScrollPositionChange);
      _handleScrollPositionChange();
    }
  }

  void _handleScrollPositionChange() {
    if (scrollController.hasClients) {
      final ScrollPosition position = scrollController.position;
      final double maxScrollExtent = position.maxScrollExtent;
      final double totalHeight = maxScrollExtent + _visibleRect.height;
      externalScroller.updateHeight(totalHeight);
    }
  }

  /// Disposes of the browser scroll strategy.
  void dispose() {
    if (scrollController.hasClients) {
      scrollController.position.removeListener(_handleScrollPositionChange);
    }
    externalScroller.removeVisibleRectListener(_updateVisibleRect);
    externalScroller.dispose();
  }
}

/// Widget that enables browser scrolling for its child.
///
/// This is automatically applied to scrollables on web when browser scrolling
/// is enabled. It can also be used manually to wrap content that should use
/// browser scrolling.
///
/// Example:
/// ```dart
/// BrowserScrollView(
///   child: ListView.builder(...),
/// )
/// ```
class BrowserScrollView extends StatefulWidget {
  const BrowserScrollView({
    super.key,
    required this.child,
    this.scrollController,
  });

  final Widget child;
  final ScrollController? scrollController;

  @override
  State<BrowserScrollView> createState() => _BrowserScrollViewState();
}

class _BrowserScrollViewState extends State<BrowserScrollView> {
  late final ScrollController _scrollController;
  late final BrowserScrollStrategy _strategy;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    
    // Get the view ID for this widget's context
    final int viewId = View.of(context).viewId;
    
    _strategy = BrowserScrollStrategy(
      scrollController: _scrollController,
      externalScroller: JsViewScroller(viewId),
    );
    
    _strategy.initialize();
  }

  @override
  void dispose() {
    _strategy.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Determines whether browser scrolling should be used for a given scrollable.
///
/// Returns true if:
/// - Running on web platform
/// - Browser scrolling is enabled globally
/// - Not explicitly disabled for this scrollable
/// - No custom scroll physics that conflict with browser scrolling
bool shouldUseBrowserScrolling({
  bool? explicitSetting,
  ScrollPhysics? physics,
}) {
  if (!kIsWeb) {
    return false;
  }

  if (explicitSetting != null) {
    return explicitSetting;
  }

  if (!_kDefaultBrowserScrollingEnabled) {
    return false;
  }

  // Check if physics would conflict with browser scrolling
  // NeverScrollableScrollPhysics means the content shouldn't scroll at all
  if (physics is NeverScrollableScrollPhysics) {
    return false;
  }

  return true;
}

/// Creates a browser scroll strategy for the given view ID.
///
/// This is called by [ScrollableState] when browser scrolling is enabled.
/// Returns an [ExternalScroller] that manages the DOM placeholder and
/// syncs with browser scroll events.
ExternalScroller createBrowserScrollStrategy(int viewId) {
  return JsViewScroller(viewId);
}

