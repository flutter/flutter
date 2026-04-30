// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/dom.dart';
import 'package:ui/ui.dart' as ui;

import 'custom_element_embedding_strategy.dart';
import 'full_page_embedding_strategy.dart';

/// Controls how a Flutter app is placed, sized and measured on the page.
///
/// The base class handles general behavior (like hot-restart cleanup), and then
/// each specialization enables different types of DOM embeddings:
///
/// * [FullPageEmbeddingStrategy] - The default behavior, where flutter takes
///   control of the whole page.
/// * [CustomElementEmbeddingStrategy] - Flutter is rendered inside a custom host
///   element, provided by the web app programmer through the engine
///   initialization.
abstract class EmbeddingStrategy {
  factory EmbeddingStrategy.create({DomElement? hostElement}) {
    if (hostElement != null) {
      return CustomElementEmbeddingStrategy(hostElement);
    } else {
      return FullPageEmbeddingStrategy();
    }
  }

  /// Sets the locale for the embedded view.
  ///
  /// This method is typically called by the Flutter framework after it has
  /// resolved the application's locale. It configures the embedded view to
  /// reflect the given locale, which is important for accessibility and for
  /// the browser to select appropriate fonts and other locale-specific resources.
  void setLocale(ui.Locale locale);

  /// The DOM element in which the Flutter view is embedded.
  /// This element is the direct parent element of the <flutter-view> element.
  DomElement get hostElement;

  /// The global event target for the Flutter view.
  DomEventTarget get globalEventTarget;

  /// Attaches the view root element into the hostElement.
  void attachViewRoot(DomElement rootElement);

  /// Whether browser-driven scrolling is supported by this embedding strategy.
  bool get supportsBrowserScrolling => false;

  /// Enables browser-driven scrolling for the outermost scrollable.
  ///
  /// When enabled, [rootElement] becomes a real scrollable DOM element,
  /// allowing the browser to handle scroll physics, momentum, and scroll
  /// chaining natively. The framework syncs its scroll position from the
  /// browser's scroll events.
  void enableBrowserScrolling(DomElement rootElement) {}

  /// Disables browser-driven scrolling, restoring the original styles.
  void disableBrowserScrolling(DomElement rootElement) {}

  /// Updates the scroll content height so the browser knows how much
  /// content is available to scroll through.
  void updateScrollContentHeight(double height) {}
}
