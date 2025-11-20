// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// A widget that manages touch event pass-through for nested scrolling on web.
///
/// This widget creates an HTML div that sits above Flutter's canvas and
/// intercepts touch and wheel events. It uses JavaScript to detect when the
/// inner scrollable has reached its boundaries and allows scroll events to
/// bubble to the parent page.
///
/// This is primarily used for nested scrolling scenarios where you have a
/// scrollable widget inside another scrollable container on web.
///
/// Example:
/// ```dart
/// BrowserScrollZone(
///   scrollController: _scrollController,
///   child: ListView.builder(
///     controller: _scrollController,
///     itemCount: 20,
///     itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   ),
/// )
/// ```
class BrowserScrollZone extends StatefulWidget {
  /// Creates a browser scroll zone.
  ///
  /// The [child] is required and will be rendered with touch event interception.
  /// The [scrollController] is optional but recommended for boundary detection.
  const BrowserScrollZone({
    super.key,
    required this.child,
    this.scrollController,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// The scroll controller for the scrollable widget inside this zone.
  ///
  /// This is used to detect when the scrollable has reached its boundaries.
  final ScrollController? scrollController;

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

    // Register a factory that creates a div with touch event interception
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final web.HTMLDivElement container = web.document.createElement('div') as web.HTMLDivElement;
        container.style
          ..width = '100%'
          ..height = '100%'
          ..touchAction = 'pan-y' // Allow vertical scrolling (we'll control it with JS)
          ..overflow = 'hidden' // Prevent any browser scrolling
          ..pointerEvents = 'auto'; // Allow the div to intercept events

        // Track touch start position for direction detection
        double? touchStartY;

        // Handle touch events for boundary detection
        container.addEventListener('touchstart', (web.TouchEvent event) {
          if (event.touches.length > 0) {
            touchStartY = event.touches.item(0)!.clientY.toDouble();
          }
        }.toJS, web.AddEventListenerOptions(passive: true));

        container.addEventListener('touchmove', (web.TouchEvent event) {
          final ScrollController? scrollController = widget.scrollController;

          // If no scroll controller, always block (defensive)
          if (scrollController == null || !scrollController.hasClients || event.touches.length == 0) {
            event.preventDefault();
            return;
          }

          final double currentY = event.touches.item(0)!.clientY.toDouble();
          final double deltaY = touchStartY != null ? currentY - touchStartY! : 0.0;
          final ScrollPosition position = scrollController.position;

          // Check if we're at boundaries and trying to scroll beyond
          final bool isAtTop = position.pixels <= position.minScrollExtent;
          final bool isAtBottom = position.pixels >= position.maxScrollExtent;
          final bool isScrollingUp = deltaY > 0; // Positive deltaY means finger moving down = scrolling up
          final bool isScrollingDown = deltaY < 0; // Negative deltaY means finger moving up = scrolling down

          // Allow event to bubble to parent if:
          // - At top and scrolling up, OR
          // - At bottom and scrolling down
          final bool shouldBubble = (isAtTop && isScrollingUp) || (isAtBottom && isScrollingDown);

          if (!shouldBubble) {
            event.preventDefault(); // Block browser scrolling
            if (kDebugMode) {
              print('[BrowserScrollZone] Blocked touch event (ListView can scroll)');
            }
          } else {
            // Allow event to bubble to parent
            if (kDebugMode) {
              print('[BrowserScrollZone] Allowing touch event to bubble (ListView at boundary)');
            }
          }
        }.toJS, web.AddEventListenerOptions(passive: false)); // Must be non-passive to call preventDefault

        container.addEventListener('touchend', (web.TouchEvent event) {
          touchStartY = null;
        }.toJS, web.AddEventListenerOptions(passive: true));

        container.addEventListener('touchcancel', (web.TouchEvent event) {
          touchStartY = null;
        }.toJS, web.AddEventListenerOptions(passive: true));

        // Block wheel events to prevent browser scrolling
        // BUT: Allow events to bubble when ListView is at boundaries
        container.addEventListener('wheel', (web.WheelEvent event) {
          final ScrollController? scrollController = widget.scrollController;

          // If no scroll controller, always block (defensive)
          if (scrollController == null || !scrollController.hasClients) {
            event.preventDefault();
            return;
          }

          final ScrollPosition position = scrollController.position;
          final double deltaY = event.deltaY.toDouble();

          // Check if we're at boundaries and trying to scroll beyond
          final bool isAtTop = position.pixels <= position.minScrollExtent;
          final bool isAtBottom = position.pixels >= position.maxScrollExtent;
          final bool isScrollingUp = deltaY < 0;
          final bool isScrollingDown = deltaY > 0;

          // Allow event to bubble to parent if:
          // - At top and scrolling up, OR
          // - At bottom and scrolling down
          final bool shouldBubble = (isAtTop && isScrollingUp) || (isAtBottom && isScrollingDown);

          if (!shouldBubble) {
            event.preventDefault(); // Block browser scrolling
            if (kDebugMode) {
              print('[BrowserScrollZone] Blocked wheel event (ListView can scroll)');
            }
          } else {
            // Allow event to bubble to parent
            if (kDebugMode) {
              print('[BrowserScrollZone] Allowing wheel event to bubble (ListView at boundary)');
            }
          }
        }.toJS);

        if (kDebugMode) {
          print('[BrowserScrollZone] Created container with touch-action: pan-y + wheel blocking');
        }

        return container;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stack the HTML div behind the Flutter widget to intercept events
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

