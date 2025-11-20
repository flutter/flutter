// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Enables browser-native scrolling for a Flutter view.
///
/// When enabled:
/// - The Flutter view becomes position:fixed
/// - A placeholder element defines the scrollable extent
/// - Browser handles all scroll events naturally
/// - Flutter compensates rendering based on scroll position
///
/// This solves the nested scrolling problem where iframes or HTML content
/// would otherwise block Flutter's scroll detection.
class BrowserScrollController {
  BrowserScrollController(this._view);

  final EngineFlutterView _view;
  DomElement? _placeholder;
  DomEventListener? _scrollListener;
  bool _enabled = false;
  double _currentScrollY = 0.0;

  /// Whether browser-driven scrolling is currently enabled.
  bool get isEnabled => _enabled;

  /// Current browser scroll position.
  double get scrollY => _currentScrollY;

  /// Enable browser-driven scrolling mode.
  void enable() {
    print('[DEBUG BrowserScrollController] enable() called');

    if (_enabled) {
      print('[DEBUG BrowserScrollController] Already enabled, returning');
      return;
    }

    print('[DEBUG BrowserScrollController] Starting enable process...');
    final DomElement rootElement = _view.dom.rootElement;

    assert(() {
      print('[DEBUG] rootElement tag: ${rootElement.tagName}');
      print('[DEBUG] rootElement id: ${rootElement.id}');
      print('[DEBUG] rootElement parent: ${rootElement.parent?.tagName}');
      print('[DEBUG] rootElement current position: ${rootElement.style.position}');
      return true;
    }());

    // Create placeholder that will define scroll extent
    // Create a simple div instead of cloning to avoid inherited styles
    _placeholder = domDocument.createElement('div');
    _placeholder!.id = 'flt-browser-scroll-placeholder';
    _placeholder!.style
      ..position =
          'relative' // Must be in document flow to create scrollable space
      ..display =
          'block' // Block element respects height
      ..height = '0px'
      ..width = '100%'
      ..pointerEvents =
          'none' // Don't intercept pointer events
      ..visibility =
          'hidden' // Invisible but takes up space
      ..margin = '0'
      ..padding = '0';

    assert(() {
      print('[DEBUG] Placeholder created with id: ${_placeholder!.id}');
      return true;
    }());

    // Insert placeholder before Flutter view in DOM
    rootElement.parent!.insertBefore(_placeholder!, rootElement);

    assert(() {
      print('[DEBUG] Placeholder inserted into DOM');
      return true;
    }());

    // Make Flutter view fixed to viewport
    // Remove 'inset' and 'bottom' to allow explicit height control
    rootElement.style.removeProperty('inset');
    rootElement.style.removeProperty('bottom');

    rootElement.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..overflow = 'hidden'; // Flutter handles internal scrolling
    // Height will be set by updateScrollExtent

    assert(() {
      print('[DEBUG] Flutter view style updated to fixed');
      print('[DEBUG] Position: ${rootElement.style.position}');
      print('[DEBUG] Top: ${rootElement.style.top}');
      print('[DEBUG] Left: ${rootElement.style.left}');
      print('[DEBUG] Right: ${rootElement.style.right}');
      print('[DEBUG] Bottom: ${rootElement.style.bottom}');
      print('[DEBUG] Height: ${rootElement.style.height}');
      print('[DEBUG] Inset: ${rootElement.style.getPropertyValue("inset")}');
      return true;
    }());

    // Enable scrolling on body to allow browser-driven scrolling
    // Inject CSS to override Flutter's default fixed positioning
    final DomHTMLStyleElement styleElement =
        domDocument.createElement('style') as DomHTMLStyleElement;
    styleElement.id = 'flt-browser-scroll-style';
    styleElement.text = '''
      html, body {
        height: auto !important;
        min-height: 100% !important;
        position: static !important;
        overflow: auto !important;
      }
    ''';
    domDocument.head!.append(styleElement);

    assert(() {
      print('[DEBUG] Browser scroll CSS injected');
      return true;
    }());

    // Listen to scroll events on window
    _scrollListener = createDomEventListener(_onScroll);
    domWindow.addEventListener('scroll', _scrollListener);

    // Also listen for resize events to maintain the height
    _resizeListener = createDomEventListener((DomEvent event) {
      assert(() {
        print('[DEBUG] Window resize detected, re-enforcing height');
        return true;
      }());
      _enforceHeight();
    });
    domWindow.addEventListener('resize', _resizeListener);

    // Mark as enabled
    _enabled = true;

    assert(() {
      print('[BrowserScrollController] Enabled for view ${_view.viewId}');
      print('[BrowserScrollController] Waiting for framework to send content height...');
      return true;
    }());
  }

  void _onScroll(DomEvent event) {
    if (!_enabled || _placeholder == null) {
      return;
    }

    // Get current scroll position
    final double scrollY =
        domDocument.documentElement?.scrollTop ?? domDocument.body?.scrollTop ?? 0.0;

    // Move the Flutter view up to compensate for scroll
    // This creates the illusion that the Flutter content is scrolling
    _view.dom.rootElement.style.transform = 'translateY(-${scrollY}px)';

    // Re-enforce height on every scroll to fight Flutter's resize logic
    _enforceHeight();

    _currentScrollY = scrollY;

    // Send scroll position to framework
    _sendScrollPositionToFramework(_currentScrollY);
  }

  /// Update the scrollable extent (height).
  ///
  /// Called when Flutter's content height changes to update the browser's
  /// scrollable area.
  void updateScrollExtent(double height) {
    print('[DEBUG] updateScrollExtent called with height: $height');
    print('[DEBUG] _placeholder: ${_placeholder != null ? "exists" : "null"}');
    print('[DEBUG] _enabled: $_enabled');

    if (_placeholder != null && _enabled) {
      _placeholder!.style.height = '${height}px';

      // Store the desired height for continuous enforcement
      _desiredHeight = height;

      // Set Flutter view's height to match content so it renders everything
      _enforceHeight();

      assert(() {
        print('[BrowserScrollController] Updated scroll extent to ${height}px');
        print('[DEBUG] Placeholder actual height style: ${_placeholder!.style.height}');
        print('[DEBUG] Flutter view height: ${_view.dom.rootElement.style.height}');
        return true;
      }());
    } else {
      print('[DEBUG] Skipping update - placeholder null or not enabled');
    }
  }

  double? _desiredHeight;
  DomEventListener? _resizeListener;
  DomMutationObserver? _heightObserver;

  /// Enforce the height setting, preventing Flutter's resize logic from overriding it.
  void _enforceHeight() {
    if (_desiredHeight == null) return;

    final DomElement rootElement = _view.dom.rootElement;

    // Use setProperty with priority 'important' to prevent Flutter's resize logic from overriding
    rootElement.style.setProperty('height', '${_desiredHeight}px', 'important');

    // Also force min-height to prevent collapsing
    rootElement.style.setProperty('min-height', '${_desiredHeight}px', 'important');

    // Set up a MutationObserver to aggressively prevent any height changes
    if (_heightObserver == null) {
      _heightObserver = createDomMutationObserver((
        JSArray<JSAny?> mutations,
        DomMutationObserver observer,
      ) {
        // Check if height was changed by Flutter's resize logic
        final String? currentHeight = rootElement.style.height;
        if (currentHeight != null && !currentHeight.contains('${_desiredHeight}px')) {
          // Flutter tried to change the height - revert it immediately!
          assert(() {
            print(
              '[DEBUG] 🛡️ Height override detected ($currentHeight), reverting to ${_desiredHeight}px',
            );
            return true;
          }());

          // Temporarily disconnect to avoid triggering ourselves
          observer.disconnect();

          rootElement.style.setProperty('height', '${_desiredHeight}px', 'important');
          rootElement.style.setProperty('min-height', '${_desiredHeight}px', 'important');

          // Reconnect to continue monitoring
          observer.observe(rootElement, attributes: true, attributeFilter: <String>['style']);
        }
      });

      // Observe style attribute changes
      _heightObserver!.observe(rootElement, attributes: true, attributeFilter: <String>['style']);

      assert(() {
        print('[DEBUG] 🛡️ MutationObserver installed to protect height');
        return true;
      }());
    }

    assert(() {
      print('[DEBUG] _enforceHeight() set height to ${_desiredHeight}px');
      return true;
    }());
  }

  void _sendScrollPositionToFramework(double scrollY) {
    // Send scroll position update as a method call to the framework
    final ByteData? message = const StandardMethodCodec().encodeMethodCall(
      MethodCall('updateScrollPosition', <String, dynamic>{
        'viewId': _view.viewId,
        'scrollY': scrollY,
      }),
    );

    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/browserscroll',
      message,
      (ByteData? _) {}, // Empty callback - no response needed
    );
  }

  /// Disable browser-driven scrolling and restore normal Flutter mode.
  /// Automatically sets a large default scroll extent for browser scrolling
  /// This provides a reasonable default that works for most content

  void disable() {
    if (!_enabled) {
      return;
    }

    // Restore normal positioning
    _view.dom.rootElement.style
      ..removeProperty('position')
      ..removeProperty('top')
      ..removeProperty('left')
      ..removeProperty('right')
      ..removeProperty('bottom')
      ..removeProperty('height')
      ..removeProperty('min-height')
      ..removeProperty('overflow')
      ..removeProperty('transform');

    // Remove injected CSS
    domDocument.getElementById('flt-browser-scroll-style')?.remove();

    // Remove placeholder
    _placeholder?.remove();
    _placeholder = null;

    // Remove scroll listener
    if (_scrollListener != null) {
      domWindow.removeEventListener('scroll', _scrollListener);
      _scrollListener = null;
    }

    // Remove resize listener
    if (_resizeListener != null) {
      domWindow.removeEventListener('resize', _resizeListener);
      _resizeListener = null;
    }

    // Disconnect MutationObserver
    if (_heightObserver != null) {
      _heightObserver!.disconnect();
      _heightObserver = null;
    }

    _enabled = false;
    _currentScrollY = 0.0;
    _desiredHeight = null;

    assert(() {
      print('[BrowserScrollController] Disabled for view ${_view.viewId}');
      return true;
    }());
  }

  /// Clean up resources.
  void dispose() {
    disable();
  }
}
