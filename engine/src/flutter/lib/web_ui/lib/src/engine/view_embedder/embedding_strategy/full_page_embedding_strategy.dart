// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;

import '../hot_restart_cache_handler.dart' show registerElementForCleanup;
import 'embedding_strategy.dart';

/// An [EmbeddingStrategy] that takes over the whole web page.
///
/// This strategy takes over the <body> element, modifies the viewport meta-tag,
/// and ensures that the root Flutter view covers the whole screen.
class FullPageEmbeddingStrategy implements EmbeddingStrategy {
  FullPageEmbeddingStrategy() {
    hostElement.setAttribute('flt-embedding', 'full-page');
    _applyViewportMeta();
    _setHostStyles();
  }

  @override
  final DomElement hostElement = domDocument.body!;

  @override
  DomEventTarget get globalEventTarget => domWindow;

  @override
  bool get supportsBrowserScrolling => true;

  bool _browserScrollingEnabled = false;

  /// Whether browser-driven scrolling is currently active.
  bool get browserScrollingEnabled => _browserScrollingEnabled;

  DomElement? _scrollHeightPlaceholder;

  // Per-child inline style snapshot taken on enable so disable can restore
  // the exact pre-enable state. Needed because some engine-managed children
  // such as <flt-semantics-host> carry inline `position: absolute` that
  // otherwise falls through to `static` when we clear the style.
  final Map<DomElement, Map<String, String>> _savedChildStyles =
      <DomElement, Map<String, String>>{};

  @override
  void setLocale(ui.Locale locale) {
    domDocument.documentElement!.setAttribute('lang', locale.toLanguageTag());
  }

  @override
  void attachViewRoot(DomElement rootElement) {
    /// Tweaks style so the rootElement works well with the hostElement.
    rootElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0';

    hostElement.append(rootElement);

    registerElementForCleanup(rootElement);
  }

  @override
  void enableBrowserScrolling(DomElement rootElement) {
    _browserScrollingEnabled = true;

    setElementStyle(hostElement, 'position', 'static');
    setElementStyle(hostElement, 'overflow', 'hidden');
    setElementStyle(hostElement, 'padding', '0');
    setElementStyle(hostElement, 'margin', '0');
    setElementStyle(hostElement, 'width', '100%');
    setElementStyle(hostElement, 'height', '100%');

    // Override body's touch-action from 'none' to 'pan-y'. The browser
    // computes effective touch-action as the intersection of an element
    // and all its ancestors. If body keeps 'none', no descendant can
    // touch-scroll regardless of its own touch-action value.
    setElementStyle(hostElement, 'touch-action', 'pan-y');

    // Make <flutter-view> the scrollable element. This is critical: the
    // flutter-view must be the scrollable so that wheel events, which land
    // on it, trigger native scrolling. If we made the body scrollable but
    // flutter-view was fixed on top, wheel events would go to flutter-view
    // and the body would never scroll.
    rootElement.style
      ..position = 'fixed'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0'
      ..overflow = 'auto';

    // Use touch-action: none so the browser does not initiate native
    // touch scrolling. Flutter handles all touch input and forwards
    // scroll deltas to the browser via the dart:ui browserScrollBy API.
    // With pan-y, the browser fires pointercancel before Flutter can
    // process the gesture.
    setElementStyle(rootElement, 'touch-action', 'none');

    // Make all existing children of flutter-view sticky so they stay
    // visible at the top of the viewport while the element scrolls.
    // This includes <flt-glass-pane>, <flt-text-editing-host>, and
    // <flt-semantics-host>.
    //
    // Snapshot each child's inline position/top/left first so disable can
    // restore them. <flt-semantics-host> in particular ships with inline
    // `position: absolute` set by StyleManager; clearing to empty would
    // drop it through to `static` and break its transform scaling.
    for (final DomElement child in rootElement.children) {
      _savedChildStyles[child] = <String, String>{
        'position': child.style.position,
        'top': child.style.top,
        'left': child.style.left,
      };
      child.style
        ..position = 'sticky'
        ..top = '0'
        ..left = '0';
    }

    // Create a placeholder element inside flutter-view that sets the
    // scroll height. This gives flutter-view real content to scroll against.
    // It must be positioned absolutely so it doesn't push the sticky
    // children down, and its height defines the total scrollable area.
    _scrollHeightPlaceholder = domDocument.createElement('div');
    _scrollHeightPlaceholder!.setAttribute('flt-scroll-placeholder', '');
    _scrollHeightPlaceholder!.style
      ..width = '1px'
      ..pointerEvents = 'none'
      ..position = 'absolute'
      ..top = '0'
      ..left = '0';

    rootElement.append(_scrollHeightPlaceholder!);

    registerElementForCleanup(_scrollHeightPlaceholder!);
  }

  @override
  void disableBrowserScrolling(DomElement rootElement) {
    _browserScrollingEnabled = false;

    _setHostStyles();

    rootElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0'
      ..overflow = '';

    setElementStyle(rootElement, 'touch-action', '');
    setElementStyle(hostElement, 'touch-action', '');

    for (final DomElement child in rootElement.children) {
      final Map<String, String>? saved = _savedChildStyles[child];
      child.style
        ..position = saved?['position'] ?? ''
        ..top = saved?['top'] ?? ''
        ..left = saved?['left'] ?? '';
    }
    _savedChildStyles.clear();

    _scrollHeightPlaceholder?.remove();
    _scrollHeightPlaceholder = null;
  }

  @override
  void updateScrollContentHeight(double height) {
    if (_scrollHeightPlaceholder != null) {
      _scrollHeightPlaceholder!.style.height = '${height}px';
    }
  }

  // Sets the global styles for a flutter app.
  void _setHostStyles() {
    setElementStyle(hostElement, 'position', 'fixed');
    setElementStyle(hostElement, 'top', '0');
    setElementStyle(hostElement, 'right', '0');
    setElementStyle(hostElement, 'bottom', '0');
    setElementStyle(hostElement, 'left', '0');
    setElementStyle(hostElement, 'overflow', 'hidden');
    setElementStyle(hostElement, 'padding', '0');
    setElementStyle(hostElement, 'margin', '0');

    setElementStyle(hostElement, 'user-select', 'none');
    setElementStyle(hostElement, '-webkit-user-select', 'none');

    // This is required to prevent the browser from doing any native touch
    // handling. If this is not done, the browser doesn't report 'pointermove'
    // events properly.
    setElementStyle(hostElement, 'touch-action', 'none');
  }

  // Sets a meta viewport tag appropriate for Flutter Web in full screen.
  void _applyViewportMeta() {
    for (final DomElement viewportMeta in domDocument.head!.querySelectorAll(
      'meta[name="viewport"]',
    )) {
      assert(() {
        // Filter out the meta tag that the engine placed on the page. This is
        // to avoid UI flicker during hot restart. Hot restart will clean up the
        // old meta tag synchronously with the first post-restart frame.
        if (!viewportMeta.hasAttribute('flt-viewport')) {
          printWarning(
            'Found an existing <meta name="viewport"> tag. Flutter Web uses its own viewport '
            'configuration for better compatibility with Flutter. This tag will be replaced.',
          );
        }
        return true;
      }());
      viewportMeta.remove();
    }

    // The meta viewport is always removed by the for method above, so we don't
    // need to do anything else here, other than create it again.
    final DomHTMLMetaElement viewportMeta = createDomHTMLMetaElement()
      ..setAttribute('flt-viewport', '')
      ..name = 'viewport'
      ..content =
          'width=device-width, initial-scale=1.0, '
          'maximum-scale=1.0, user-scalable=no';

    domDocument.head!.append(viewportMeta);

    registerElementForCleanup(viewportMeta);
  }
}
