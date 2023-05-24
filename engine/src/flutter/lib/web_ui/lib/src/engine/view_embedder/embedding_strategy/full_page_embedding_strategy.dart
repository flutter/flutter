// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/util.dart' show setElementStyle;

import 'embedding_strategy.dart';

/// An [EmbeddingStrategy] that takes over the whole web page.
///
/// This strategy takes over the <body> element, modifies the viewport meta-tag,
/// and ensures that the root Flutter view covers the whole screen.
class FullPageEmbeddingStrategy extends EmbeddingStrategy {
  @override
  void initialize({
    Map<String, String>? hostElementAttributes,
  }) {
    // ignore:avoid_function_literals_in_foreach_calls
    hostElementAttributes?.entries.forEach((MapEntry<String, String> entry) {
      _setHostAttribute(entry.key, entry.value);
    });
    _setHostAttribute('flt-embedding', 'full-page');

    _applyViewportMeta();
    _setHostStyles();
  }

  @override
  void attachGlassPane(DomElement glassPaneElement) {
    /// Tweaks style so the glassPane works well with the hostElement.
    glassPaneElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0';

    domDocument.body!.append(glassPaneElement);

    registerElementForCleanup(glassPaneElement);
  }

  @override
  void attachResourcesHost(DomElement resourceHost, {DomElement? nextTo}) {
    domDocument.body!.insertBefore(resourceHost, nextTo);

    registerElementForCleanup(resourceHost);
  }

  @override
  void disableContextMenu() => disableContextMenuOn(domWindow);

  @override
  void enableContextMenu() => enableContextMenuOn(domWindow);

  void _setHostAttribute(String name, String value) {
    domDocument.body!.setAttribute(name, value);
  }

  // Sets the global styles for a flutter app.
  void _setHostStyles() {
    final DomHTMLBodyElement bodyElement = domDocument.body!;

    setElementStyle(bodyElement, 'position', 'fixed');
    setElementStyle(bodyElement, 'top', '0');
    setElementStyle(bodyElement, 'right', '0');
    setElementStyle(bodyElement, 'bottom', '0');
    setElementStyle(bodyElement, 'left', '0');
    setElementStyle(bodyElement, 'overflow', 'hidden');
    setElementStyle(bodyElement, 'padding', '0');
    setElementStyle(bodyElement, 'margin', '0');

    setElementStyle(bodyElement, 'user-select', 'none');
    setElementStyle(bodyElement, '-webkit-user-select', 'none');

    // This is required to prevent the browser from doing any native touch
    // handling. If this is not done, the browser doesn't report 'pointermove'
    // events properly.
    setElementStyle(bodyElement, 'touch-action', 'none');
  }

  // Sets a meta viewport tag appropriate for Flutter Web in full screen.
  void _applyViewportMeta() {
    for (final DomElement viewportMeta
        in domDocument.head!.querySelectorAll('meta[name="viewport"]')) {
      assert(() {
        // Filter out the meta tag that the engine placed on the page. This is
        // to avoid UI flicker during hot restart. Hot restart will clean up the
        // old meta tag synchronously with the first post-restart frame.
        if (!viewportMeta.hasAttribute('flt-viewport')) {
          print(
            'WARNING: found an existing <meta name="viewport"> tag. Flutter '
            'Web uses its own viewport configuration for better compatibility '
            'with Flutter. This tag will be replaced.',
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
      ..content = 'width=device-width, initial-scale=1.0, '
          'maximum-scale=1.0, user-scalable=no';

    domDocument.head!.append(viewportMeta);

    registerElementForCleanup(viewportMeta);
  }
}
