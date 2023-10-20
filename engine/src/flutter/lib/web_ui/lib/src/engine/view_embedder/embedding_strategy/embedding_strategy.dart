// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/dom.dart';

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

  void initialize({
    Map<String, String>? hostElementAttributes,
  });

  /// Attaches the glassPane element into the hostElement.
  void attachGlassPane(DomElement glassPaneElement);

  /// Attaches the resourceHost element into the hostElement.
  void attachResourcesHost(DomElement resourceHost, {DomElement? nextTo});
}
