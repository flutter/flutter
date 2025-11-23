// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Web-specific widget for nested scrolling with boundary detection.
///
/// This file provides [BrowserScrollZone], which enables smooth nested scrolling
/// on Flutter web by detecting scroll boundaries and allowing touch events to
/// pass through to parent scrollables.
library;

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'basic.dart';
import 'framework.dart';
import 'platform_view.dart';
import 'scroll_controller.dart';

/// A widget that enables boundary detection for nested scrollables on web.
///
/// When a scrollable wrapped in [BrowserScrollZone] reaches its scroll
/// boundaries (top or bottom), touch and wheel events will pass through to
/// parent scrollables, enabling natural nested scrolling behavior.
///
/// This widget is only effective on web platforms. On other platforms, it
/// simply returns its child without any modifications.
///
/// ## Use Cases
///
/// [BrowserScrollZone] is useful when you have a scrollable (like [ListView])
/// nested inside another scrollable area and want smooth scrolling transitions
/// at boundaries:
///
/// - Nested lists in a scrollable page
/// - Modal dialogs with scrollable content
/// - Embedded scrollable regions
/// - Any nested scrolling scenario on web
///
/// ## How It Works
///
/// [BrowserScrollZone] creates an HTML platform view that sits above Flutter's
/// canvas. This platform view intercepts touch and wheel events before they
/// reach Flutter's rendering system, allowing conditional event handling based
/// on the scroll position:
///
/// - **Not at boundary**: Events are prevented, Flutter handles scrolling
/// - **At top + scrolling up**: Events pass through to parent
/// - **At bottom + scrolling down**: Events pass through to parent
///
/// ## Requirements
///
/// - Requires a [ScrollController] to detect scroll position
/// - Only works on web platform (no-op on other platforms)
/// - Child should be a scrollable widget (ListView, GridView, etc.)
///
/// ## Example
///
/// ```dart
/// final controller = ScrollController();
///
/// SingleChildScrollView(
///   browserScrolling: true, // Enable browser scrolling for outer
///   child: Column(
///     children: [
///       Text('Header'),
///       SizedBox(
///         height: 400,
///         child: BrowserScrollZone(
///           scrollController: controller,
///           child: ListView.builder(
///             controller: controller,
///             itemCount: 30,
///             itemBuilder: (context, index) => ListTile(
///               title: Text('Item $index'),
///             ),
///           ),
///         ),
///       ),
///       Text('Footer'),
///     ],
///   ),
/// )
/// ```
///
/// ## Important Notes
///
/// - The [ScrollController] must be attached to the child scrollable
/// - Boundary detection only works when the controller has clients
/// - The widget creates a platform view, which has some performance overhead
/// - Works with both touch and mouse wheel events
///
/// See also:
///
/// * [Scrollable.browserScrolling], which enables browser-driven scrolling
/// * [ScrollController], which is required for boundary detection
/// * [HtmlElementView], which is used internally to create the platform view
class BrowserScrollZone extends StatefulWidget {
  /// Creates a [BrowserScrollZone] that enables boundary detection for nested scrolling.
  ///
  /// The [child] parameter must not be null and should be a scrollable widget.
  ///
  /// The [scrollController] parameter is required and must be the same controller
  /// attached to the child scrollable widget. It is used to detect scroll position
  /// and determine when to allow events to pass through to parent scrollables.
  const BrowserScrollZone({
    super.key,
    required this.child,
    required this.scrollController,
  });

  /// The scrollable widget to wrap.
  ///
  /// This should typically be a [ListView], [GridView], [SingleChildScrollView],
  /// or any other scrollable widget.
  final Widget child;

  /// The scroll controller attached to the child scrollable.
  ///
  /// This controller is used to detect the current scroll position and determine
  /// when the scrollable is at its boundaries (top or bottom).
  ///
  /// The same controller must be passed to both [BrowserScrollZone] and the
  /// child scrollable widget for boundary detection to work correctly.
  final ScrollController scrollController;

  @override
  State<BrowserScrollZone> createState() => _BrowserScrollZoneState();
}

class _BrowserScrollZoneState extends State<BrowserScrollZone> {
  static int _nextViewId = 0;
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'flutter-browser-scroll-zone-${_nextViewId++}';

    // Only register platform view on web
    if (kIsWeb) {
      _registerPlatformView();
    }
  }

  void _registerPlatformView() {
    // Register a factory that creates a div with boundary detection
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final container = web.document.createElement('div') as web.HTMLDivElement;
        container.style
          ..width = '100%'
          ..height = '100%'
          ..touchAction = 'pan-y' // Allow vertical scrolling (controlled by JS)
          ..overflow = 'hidden' // Prevent browser scrolling
          ..pointerEvents = 'auto'; // Allow event interception

        // Track touch start position for direction detection
        double? touchStartY;

        // Handle touch events for boundary detection
        container.addEventListener('touchstart', (web.TouchEvent event) {
          if (event.touches.length > 0) {
            touchStartY = event.touches.item(0)!.clientY.toDouble();
          }
        }.toJS, web.AddEventListenerOptions(passive: true));

        container.addEventListener('touchmove', (web.TouchEvent event) {
          final scrollController = widget.scrollController;

          // If no scroll controller or no clients, block all events
          if (!scrollController.hasClients || event.touches.length == 0) {
            event.preventDefault();
            return;
          }

          final currentY = event.touches.item(0)!.clientY.toDouble();
          final deltaY = touchStartY != null ? currentY - touchStartY! : 0.0;
          final position = scrollController.position;

          // Check if we're at boundaries and trying to scroll beyond
          final isAtTop = position.pixels <= position.minScrollExtent;
          final isAtBottom = position.pixels >= position.maxScrollExtent;
          final isScrollingUp = deltaY > 0; // Positive deltaY = finger down = scroll up
          final isScrollingDown = deltaY < 0; // Negative deltaY = finger up = scroll down

          // Allow event to bubble to parent if:
          // - At top and scrolling up, OR
          // - At bottom and scrolling down
          final shouldBubble = (isAtTop && isScrollingUp) || (isAtBottom && isScrollingDown);

          if (!shouldBubble) {
            event.preventDefault(); // Block event, Flutter handles it
            if (kDebugMode) {
              print('[BrowserScrollZone] Blocked touch event (scrollable can scroll)');
            }
          } else {
            // Allow event to bubble to parent
            if (kDebugMode) {
              print('[BrowserScrollZone] Allowing touch event to bubble (at boundary)');
            }
          }
        }.toJS, web.AddEventListenerOptions(passive: false)); // Must be non-passive to call preventDefault

        container.addEventListener('touchend', (web.TouchEvent event) {
          touchStartY = null;
        }.toJS, web.AddEventListenerOptions(passive: true));

        container.addEventListener('touchcancel', (web.TouchEvent event) {
          touchStartY = null;
        }.toJS, web.AddEventListenerOptions(passive: true));

        // Handle wheel events for boundary detection (mouse scroll)
        container.addEventListener('wheel', (web.WheelEvent event) {
          final scrollController = widget.scrollController;

          // If no clients, block all events
          if (!scrollController.hasClients) {
            event.preventDefault();
            return;
          }

          final position = scrollController.position;
          final deltaY = event.deltaY.toDouble();

          // Check if we're at boundaries and trying to scroll beyond
          final isAtTop = position.pixels <= position.minScrollExtent;
          final isAtBottom = position.pixels >= position.maxScrollExtent;
          final isScrollingUp = deltaY < 0; // Negative deltaY = scroll up
          final isScrollingDown = deltaY > 0; // Positive deltaY = scroll down

          // Allow event to bubble to parent if:
          // - At top and scrolling up, OR
          // - At bottom and scrolling down
          final shouldBubble = (isAtTop && isScrollingUp) || (isAtBottom && isScrollingDown);

          if (!shouldBubble) {
            event.preventDefault(); // Block event, Flutter handles it
            if (kDebugMode) {
              print('[BrowserScrollZone] Blocked wheel event (scrollable can scroll)');
            }
          } else {
            // Allow event to bubble to parent
            if (kDebugMode) {
              print('[BrowserScrollZone] Allowing wheel event to bubble (at boundary)');
            }
          }
        }.toJS);

        if (kDebugMode) {
          print('[BrowserScrollZone] Created platform view with boundary detection');
        }

        return container;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, just return the child
    if (!kIsWeb) {
      return widget.child;
    }

    // On web, stack the platform view behind the child
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: HtmlElementView(viewType: _viewId),
        ),
        widget.child,
      ],
    );
  }
}

