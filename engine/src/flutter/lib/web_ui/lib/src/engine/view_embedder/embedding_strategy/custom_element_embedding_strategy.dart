// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/dom.dart';

import '../hot_restart_cache_handler.dart' show registerElementForCleanup;
import 'embedding_strategy.dart';

/// An [EmbeddingStrategy] that renders flutter inside a target host element.
///
/// This strategy attempts to minimize DOM modifications outside of the host
/// element, so it plays "nice" with other web frameworks.
class CustomElementEmbeddingStrategy implements EmbeddingStrategy {
  /// Creates a [CustomElementEmbeddingStrategy] to embed a Flutter view into [_hostElement].
  CustomElementEmbeddingStrategy(this._hostElement) {
    _hostElement.clearChildren();
  }

  /// The target element in which this strategy will embedd Flutter.
  final DomElement _hostElement;

  @override
  void initialize({
    Map<String, String>? hostElementAttributes,
  }) {
    // ignore:avoid_function_literals_in_foreach_calls
    hostElementAttributes?.entries.forEach((MapEntry<String, String> entry) {
      _setHostAttribute(entry.key, entry.value);
    });
    _setHostAttribute('flt-embedding', 'custom-element');
  }

  @override
  void attachGlassPane(DomElement glassPaneElement) {
    glassPaneElement
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.overflow = 'hidden'
      ..style.position = 'relative';

    _hostElement.appendChild(glassPaneElement);

    registerElementForCleanup(glassPaneElement);
  }

  @override
  void attachResourcesHost(DomElement resourceHost, {DomElement? nextTo}) {
    _hostElement.insertBefore(resourceHost, nextTo);

    registerElementForCleanup(resourceHost);
  }

  void _setHostAttribute(String name, String value) {
    _hostElement.setAttribute(name, value);
  }
}
