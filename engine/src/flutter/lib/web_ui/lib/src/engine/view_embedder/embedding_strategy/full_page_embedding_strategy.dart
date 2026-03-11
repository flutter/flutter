// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/initialization.dart' show registerHotRestartListener;
import 'package:ui/src/engine/platform_dispatcher.dart';
import 'package:ui/src/engine/services.dart';
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
    _registerPrintListeners();
  }

  late final DomEventListener _beforePrintListener;
  late final DomEventListener _afterPrintListener;

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

  /// Registers beforeprint/afterprint listeners to temporarily lift the
  /// `position: fixed` and `overflow: hidden` styles from <body> while the
  /// browser captures the print snapshot.
  ///
  /// These styles are required at runtime to fill the viewport, but during
  /// printing they prevent the browser from seeing content beyond the visible
  /// area. See: https://github.com/flutter/flutter/issues/182817
  void _registerPrintListeners() {
    _beforePrintListener = createDomEventListener(_onBeforePrint);
    _afterPrintListener = createDomEventListener(_onAfterPrint);
    domWindow.addEventListener('beforeprint', _beforePrintListener);
    domWindow.addEventListener('afterprint', _afterPrintListener);
    registerHotRestartListener(() {
      domWindow.removeEventListener('beforeprint', _beforePrintListener);
      domWindow.removeEventListener('afterprint', _afterPrintListener);
    });
  }

  void _onBeforePrint(DomEvent _) {
    setElementStyle(hostElement, 'position', 'absolute');
    setElementStyle(hostElement, 'overflow', 'visible');
    // Enable print mode on the view so that `handleFrameworkResize` uses the
    // expanded canvas size requested by the framework rather than re-reading
    // `visualViewport.height`, which does not change during printing.
    EnginePlatformDispatcher.instance.implicitView?.isPrinting = true;
    _sendSystemMessage('beforeprint');
  }

  void _onAfterPrint(DomEvent _) {
    setElementStyle(hostElement, 'position', 'fixed');
    setElementStyle(hostElement, 'overflow', 'hidden');
    // Disable print mode so that `handleFrameworkResize` resumes reading from
    // `visualViewport` rather than using the expanded framework-requested size.
    EnginePlatformDispatcher.instance.implicitView?.isPrinting = false;
    _sendSystemMessage('afterprint');
  }

  /// Encodes [type] as a system message and delivers it synchronously to the
  /// framework on the `flutter/system` channel via [invokeOnPlatformMessage].
  void _sendSystemMessage(String type) {
    final ByteData? message = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'type': type,
    });
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage('flutter/system', message, (_) {});
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
