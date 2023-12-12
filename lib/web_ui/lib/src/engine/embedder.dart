// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../engine.dart' show buildMode, renderer;
import 'browser_detection.dart';
import 'configuration.dart';
import 'dom.dart';
import 'window.dart';

/// Controls the placement and lifecycle of a Flutter view on the web page.
///
/// Manages several top-level elements that host Flutter-generated content,
/// including:
///
/// - [flutterViewElement], the root element of a Flutter view.
/// - [glassPaneElement], the glass pane element that hosts the shadowDOM.
/// - [glassPaneShadow], the shadow root used to isolate Flutter-rendered
///   content from the surrounding page content, including from the platform
///   views.
/// - [sceneElement], the element that hosts Flutter layers and pictures, and
///   projects platform views.
/// - [sceneHostElement], the anchor that provides a stable location in the DOM
///   tree for the [sceneElement].
/// - [semanticsHostElement], hosts the ARIA-annotated semantics tree.
///
/// This class is currently a singleton, but it'll possibly need to morph to have
/// multiple instances in a multi-view scenario. (One ViewEmbedder per FlutterView).
class FlutterViewEmbedder {
  /// Creates a FlutterViewEmbedder.
  FlutterViewEmbedder() {
    reset();
  }

  /// A child element of body outside the shadowroot that hosts
  /// global resources such svg filters and clip paths when using webkit.
  DomElement? _resourcesHost;

  DomElement get _flutterViewElement => window.dom.rootElement;
  DomShadowRoot get _glassPaneShadow => window.dom.renderingHost;

  void reset() {
    // How was the current renderer selected?
    const String rendererSelection = FlutterConfiguration.flutterWebAutoDetect
        ? 'auto-selected'
        : 'requested explicitly';

    // Initializes the embeddingStrategy so it can host a single-view Flutter app.
    window.embeddingStrategy.initialize(
      hostElementAttributes: <String, String>{
        'flt-renderer': '${renderer.rendererTag} ($rendererSelection)',
        'flt-build-mode': buildMode,
        // TODO(mdebbar): Disable spellcheck until changes in the framework and
        // engine are complete.
        'spellcheck': 'false',
      },
    );

    renderer.reset(this);
  }

  /// Add an element as a global resource to be referenced by CSS.
  ///
  /// This call create a global resource host element on demand and either
  /// place it as first element of body(webkit), or as a child of
  /// glass pane element for other browsers to make sure url resolution
  /// works correctly when content is inside a shadow root.
  void addResource(DomElement element) {
    final bool isWebKit = browserEngine == BrowserEngine.webkit;
    if (_resourcesHost == null) {
      final DomElement resourcesHost = domDocument
          .createElement('flt-svg-filters')
        ..style.visibility = 'hidden';
      if (isWebKit) {
        // The resourcesHost *must* be a sibling of the glassPaneElement.
        window.embeddingStrategy.attachResourcesHost(resourcesHost,
            nextTo: _flutterViewElement);
      } else {
        _glassPaneShadow.insertBefore(resourcesHost, _glassPaneShadow.firstChild);
      }
      _resourcesHost = resourcesHost;
    }
    _resourcesHost!.append(element);
  }

  /// Removes a global resource element.
  void removeResource(DomElement? element) {
    if (element == null) {
      return;
    }
    assert(element.parentNode == _resourcesHost);
    element.remove();
  }
}

/// The embedder singleton.
///
/// [ensureFlutterViewEmbedderInitialized] must be called prior to calling this
/// getter.
FlutterViewEmbedder get flutterViewEmbedder {
  final FlutterViewEmbedder? embedder = _flutterViewEmbedder;
  assert(() {
    if (embedder == null) {
      throw StateError(
          'FlutterViewEmbedder not initialized. Call `ensureFlutterViewEmbedderInitialized()` '
          'prior to calling the `flutterViewEmbedder` getter.');
    }
    return true;
  }());
  return embedder!;
}

FlutterViewEmbedder? _flutterViewEmbedder;

/// Initializes the [FlutterViewEmbedder], if it's not already initialized.
FlutterViewEmbedder ensureFlutterViewEmbedderInitialized() {
  // FlutterViewEmbedder needs the implicit view to be initialized because it
  // uses some of its members e.g. `embeddingStrategy`, `onResize`.
  ensureImplicitViewInitialized();
  return _flutterViewEmbedder ??= FlutterViewEmbedder();
}
