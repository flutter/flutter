// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'seo_node.dart';

/// Stub implementation of SEO DOM operations for non-web platforms.
///
/// On mobile/desktop, SEO functionality is a no-op since there are no
/// search engine crawlers indexing native apps.
class SeoDomOperations {
  /// Creates a stub DOM operations handler.
  SeoDomOperations();

  /// Whether this platform supports SEO DOM operations.
  bool get isSupported => false;

  /// Initializes the SEO root element (no-op on non-web).
  void initialize({bool debugVisible = false}) {
    // No-op on non-web platforms
  }

  /// Creates a DOM element from an SEO node (no-op on non-web).
  Object? createElement(SeoNode node) {
    return null;
  }

  /// Appends a child element to a parent (no-op on non-web).
  void appendChild(Object? parent, Object? child) {
    // No-op on non-web platforms
  }

  /// Removes an element from the DOM (no-op on non-web).
  void removeElement(Object? element) {
    // No-op on non-web platforms
  }

  /// Updates an element's content (no-op on non-web).
  void updateElement(Object? element, SeoNode node) {
    // No-op on non-web platforms
  }

  /// Sets the visibility of the SEO root for debugging (no-op on non-web).
  void setDebugVisible(bool visible) {
    // No-op on non-web platforms
  }

  /// Updates the document head with meta tags (no-op on non-web).
  void updateHead({
    String? title,
    String? description,
    String? canonicalUrl,
    String? ogTitle,
    String? ogDescription,
    String? ogImage,
    String? ogUrl,
    String? ogType,
    String? twitterCard,
    String? twitterTitle,
    String? twitterDescription,
    String? twitterImage,
    String? robots,
    Map<String, String>? customMeta,
  }) {
    // No-op on non-web platforms
  }

  /// Adds structured data JSON-LD to the document by ID (no-op on non-web).
  void addStructuredDataById(String id, String jsonString) {
    // No-op on non-web platforms
  }

  /// Removes structured data from the document by ID (no-op on non-web).
  void removeStructuredDataById(String id) {
    // No-op on non-web platforms
  }

  /// Returns the root element (null on non-web).
  Object? get rootElement => null;

  /// Disposes of resources (no-op on non-web).
  void dispose() {
    // No-op on non-web platforms
  }
}
