// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'seo_tag.dart';

/// Represents a node in the SEO Shadow Tree.
///
/// Each [SeoNode] corresponds to a semantic HTML element that will be
/// generated in the DOM for search engine crawlers to index.
///
/// This class is immutable and can be compared for equality to enable
/// efficient tree diffing during updates.
///
/// {@category SEO}
@immutable
class SeoNode {
  /// Creates an SEO node with the given properties.
  ///
  /// Either [text] or [textContent] can be used to specify text content.
  /// If both are provided, [textContent] takes precedence.
  const SeoNode({
    required this.tag,
    String? text,
    String? textContent,
    this.attributes = const <String, String>{},
    this.children = const <SeoNode>[],
  }) : text = textContent ?? text;

  /// Creates an SEO node for a heading element.
  const SeoNode.heading({
    required int level,
    required String text,
    Map<String, String> attributes = const <String, String>{},
  }) : this(
         tag: level == 1
             ? SeoTag.h1
             : level == 2
             ? SeoTag.h2
             : level == 3
             ? SeoTag.h3
             : level == 4
             ? SeoTag.h4
             : level == 5
             ? SeoTag.h5
             : SeoTag.h6,
         text: text,
         attributes: attributes,
       );

  /// Creates an SEO node for a link element.
  factory SeoNode.link({required String href, required String text, String? title, String? rel}) {
    return SeoNode(
      tag: SeoTag.a,
      text: text,
      attributes: <String, String>{
        'href': href,
        if (title != null) 'title': title,
        if (rel != null) 'rel': rel,
      },
    );
  }

  /// Creates an SEO node for an image element.
  factory SeoNode.image({
    required String src,
    required String alt,
    int? width,
    int? height,
    String loading = 'lazy',
  }) {
    return SeoNode(
      tag: SeoTag.img,
      attributes: <String, String>{
        'src': src,
        'alt': alt,
        if (width != null) 'width': width.toString(),
        if (height != null) 'height': height.toString(),
        'loading': loading,
      },
    );
  }

  /// Creates an SEO node for a paragraph element.
  const SeoNode.paragraph({
    required String text,
    Map<String, String> attributes = const <String, String>{},
  }) : this(tag: SeoTag.p, text: text, attributes: attributes);

  /// Creates an SEO node for a list element.
  factory SeoNode.list({required List<String> items, bool ordered = false}) {
    return SeoNode(
      tag: ordered ? SeoTag.ol : SeoTag.ul,
      children: items.map((String item) => SeoNode(tag: SeoTag.li, text: item)).toList(),
    );
  }

  /// The HTML tag for this node.
  final SeoTag tag;

  /// The text content of this node.
  ///
  /// If null, the node contains only children (no direct text content).
  final String? text;

  /// Alias for [text] for compatibility.
  String? get textContent => text;

  /// HTML attributes for this node.
  ///
  /// Common attributes include:
  /// - `href` for links
  /// - `src`, `alt` for images
  /// - `class`, `id` for styling/identification
  /// - `data-*` for custom data attributes
  final Map<String, String> attributes;

  /// Child nodes contained within this node.
  final List<SeoNode> children;

  /// Whether this node has any content (text or children).
  bool get hasContent => text != null || children.isNotEmpty;

  /// Returns a copy of this node with the given properties replaced.
  SeoNode copyWith({
    SeoTag? tag,
    String? text,
    Map<String, String>? attributes,
    List<SeoNode>? children,
  }) {
    return SeoNode(
      tag: tag ?? this.tag,
      text: text ?? this.text,
      attributes: attributes ?? this.attributes,
      children: children ?? this.children,
    );
  }

  /// Converts this node to an HTML string.
  ///
  /// This is used for server-side rendering and debugging.
  String toHtml({int indent = 0}) {
    final buffer = StringBuffer();
    final padding = '  ' * indent;
    final tagName = tag.tagName;

    // Build attributes string
    final attrString = attributes.entries
        .map((e) => '${e.key}="${_escapeAttribute(e.value)}"')
        .join(' ');

    if (tag.isVoidElement) {
      // Self-closing tag (e.g., <img>)
      buffer.write('$padding<$tagName${attrString.isNotEmpty ? ' $attrString' : ''}>');
    } else if (children.isEmpty && text != null) {
      // Inline text content
      buffer.write('$padding<$tagName${attrString.isNotEmpty ? ' $attrString' : ''}>');
      buffer.write(_escapeHtml(text!));
      buffer.write('</$tagName>');
    } else {
      // Block element with children
      buffer.writeln('$padding<$tagName${attrString.isNotEmpty ? ' $attrString' : ''}>');
      if (text != null) {
        buffer.writeln('$padding  ${_escapeHtml(text!)}');
      }
      for (final child in children) {
        buffer.writeln(child.toHtml(indent: indent + 1));
      }
      buffer.write('$padding</$tagName>');
    }

    return buffer.toString();
  }

  /// Escapes HTML special characters in text content.
  static String _escapeHtml(String text) {
    return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }

  /// Escapes special characters in attribute values.
  static String _escapeAttribute(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SeoNode &&
        other.tag == tag &&
        other.text == text &&
        mapEquals(other.attributes, attributes) &&
        listEquals(other.children, children);
  }

  @override
  int get hashCode =>
      Object.hash(tag, text, Object.hashAllUnordered(attributes.entries), Object.hashAll(children));

  @override
  String toString() =>
      'SeoNode(${tag.tagName}, text: $text, '
      'attributes: $attributes, children: ${children.length})';
}

/// A mutable builder for constructing [SeoNode] trees.
///
/// This is useful when building SEO trees programmatically.
class SeoNodeBuilder {
  /// Creates a builder for the specified tag.
  SeoNodeBuilder(this.tag);

  /// The HTML tag for the node being built.
  final SeoTag tag;

  /// The text content.
  String? text;

  /// The HTML attributes.
  final Map<String, String> attributes = <String, String>{};

  /// The child nodes.
  final List<SeoNode> children = <SeoNode>[];

  /// Sets the text content.
  SeoNodeBuilder setText(String value) {
    text = value;
    return this;
  }

  /// Sets an attribute.
  SeoNodeBuilder setAttribute(String key, String value) {
    attributes[key] = value;
    return this;
  }

  /// Sets multiple attributes.
  SeoNodeBuilder setAttributes(Map<String, String> attrs) {
    attributes.addAll(attrs);
    return this;
  }

  /// Adds a child node.
  SeoNodeBuilder addChild(SeoNode child) {
    children.add(child);
    return this;
  }

  /// Adds multiple child nodes.
  SeoNodeBuilder addChildren(Iterable<SeoNode> nodes) {
    children.addAll(nodes);
    return this;
  }

  /// Builds the immutable [SeoNode].
  SeoNode build() {
    return SeoNode(
      tag: tag,
      text: text,
      attributes: Map<String, String>.unmodifiable(attributes),
      children: List<SeoNode>.unmodifiable(children),
    );
  }
}
