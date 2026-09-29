// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;

import '../hot_restart_cache_handler.dart' show registerElementForCleanup;
import '../viewport_fit.dart';
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
    final List<DomElement> existingMetas = domDocument.head!
        .querySelectorAll('meta[name="viewport"]')
        .toList();

    // Carry the `viewport-fit` of the tags that are about to be removed over to
    // the tag that replaces them.
    //
    // `viewport-fit` is how an app tells the browser that it wants to draw
    // under display cutouts and rounded corners, and it is also what makes the
    // browser report non-zero `env(safe-area-inset-*)` values, which back
    // `ui.FlutterView.viewPadding`. Dropping it would leave apps with no way to
    // opt into a full-bleed layout, and would make `SafeArea` a no-op.
    // See https://github.com/flutter/flutter/issues/84833.
    //
    // The assignment is unconditional, so that the last tag on the page wins,
    // including when it declares no `viewport-fit` at all. That is how the
    // browser resolves several viewport meta tags: each one is parsed into a
    // fresh set of viewport arguments that replaces the previous one, so the
    // descriptors that the last tag omits go back to their defaults.
    //
    // This also preserves the value across hot restarts, because the tags being
    // read include the `flt-viewport` tag written by the previous run of the
    // engine.
    ViewportFit? viewportFit;
    for (final viewportMeta in existingMetas) {
      viewportFit = readViewportFit(viewportMeta.getAttribute('content'));
    }

    // These viewport settings are chosen to be accessibility-friendly, notably,
    // `user-scalable=no` is not used to comply with WCAG 2 rules.
    final String content = <String>[
      'width=device-width',
      'initial-scale=1.0',
      'maximum-scale=5.0',
      if (viewportFit != null) viewportFit.descriptor,
    ].join(', ');

    assert(() {
      _warnAboutDroppedDescriptors(existingMetas, content);
      return true;
    }());

    for (final viewportMeta in existingMetas) {
      viewportMeta.remove();
    }

    final DomHTMLMetaElement viewportMeta = createDomHTMLMetaElement()
      ..setAttribute('flt-viewport', '')
      ..name = 'viewport'
      ..content = content;

    domDocument.head!.append(viewportMeta);

    // This must remain the first `registerElementForCleanup` call of the boot
    // sequence. The first call is what sweeps the elements registered by the
    // previous run of the app off the page, and the tags read above are among
    // them.
    registerElementForCleanup(viewportMeta);
  }

  // Warns about each tag in [existingMetas] that says something the tag the
  // engine is about to write, whose `content` is [content], does not.
  //
  // A page that only declares descriptors the engine writes anyway — which is
  // what the `flutter create` web template suggests, so that an app can opt
  // into a full-bleed layout — loses nothing by being replaced, and warning
  // about it would be telling developers off for following our own advice.
  static void _warnAboutDroppedDescriptors(List<DomElement> existingMetas, String content) {
    final Map<String, String> written = parseViewportContent(content);
    for (final viewportMeta in existingMetas) {
      // Skip the tag that the engine placed on the page on a previous run. It
      // is still here because hot restart cleans the old tag up synchronously
      // with the first post-restart frame.
      if (viewportMeta.hasAttribute('flt-viewport')) {
        continue;
      }
      final List<String> dropped =
          (parseViewportContent(viewportMeta.getAttribute('content')).entries
                .where(
                  (MapEntry<String, String> descriptor) =>
                      written[descriptor.key] != descriptor.value,
                )
                .map((MapEntry<String, String> descriptor) => descriptor.key)
                .toList())
            ..sort();
      if (dropped.isNotEmpty) {
        printWarning(
          'Found an existing <meta name="viewport"> tag. Flutter Web uses its own viewport '
          'configuration for better compatibility with Flutter, so ${dropped.join(', ')} '
          'will be ignored. Its `viewport-fit`, if any, is preserved.',
        );
      }
    }
  }
}
