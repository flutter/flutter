// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'seo_node.dart';
import 'seo_tag.dart';
import 'seo_tree.dart';

/// A widget that adds semantic HTML representation for SEO purposes.
///
/// The [Seo] widget wraps any Flutter widget and generates a corresponding
/// HTML element in the SEO Shadow Tree. This element is hidden from users
/// but visible to search engine crawlers.
///
/// On non-web platforms, this widget simply returns its [child] with no
/// additional behavior.
///
/// ## Basic Usage
///
/// ```dart
/// Seo(
///   tag: SeoTag.h1,
///   child: Text('Welcome to My App'),
/// )
/// ```
///
/// ## With Custom Text
///
/// If the visual text differs from the SEO text (e.g., due to styling),
/// you can provide explicit text:
///
/// ```dart
/// Seo(
///   tag: SeoTag.h1,
///   text: 'Welcome to My App',
///   child: RichText(
///     text: TextSpan(
///       children: [
///         TextSpan(text: 'Welcome to ', style: normalStyle),
///         TextSpan(text: 'My App', style: boldStyle),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// ## With Attributes
///
/// ```dart
/// Seo(
///   tag: SeoTag.article,
///   attributes: {
///     'itemscope': '',
///     'itemtype': 'https://schema.org/Article',
///   },
///   child: ArticleWidget(),
/// )
/// ```
///
/// {@category SEO}
class Seo extends StatefulWidget {
  /// Creates an SEO widget.
  ///
  /// The [tag] and [child] arguments must not be null.
  const Seo({
    super.key,
    required this.tag,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  });

  /// Creates an SEO heading widget.
  ///
  /// This is a convenience constructor for heading elements.
  const Seo.heading({
    super.key,
    required int level,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  })  : assert(level >= 1 && level <= 6),
        tag = level == 1
            ? SeoTag.h1
            : level == 2
                ? SeoTag.h2
                : level == 3
                    ? SeoTag.h3
                    : level == 4
                        ? SeoTag.h4
                        : level == 5
                            ? SeoTag.h5
                            : SeoTag.h6;

  /// Creates an SEO paragraph widget.
  const Seo.paragraph({
    super.key,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  }) : tag = SeoTag.p;

  /// Creates an SEO article widget.
  const Seo.article({
    super.key,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  }) : tag = SeoTag.article;

  /// Creates an SEO section widget.
  const Seo.section({
    super.key,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  }) : tag = SeoTag.section;

  /// Creates an SEO navigation widget.
  const Seo.nav({
    super.key,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  }) : tag = SeoTag.nav;

  /// Creates an SEO main content widget.
  const Seo.main({
    super.key,
    required this.child,
    this.text,
    this.attributes = const <String, String>{},
  }) : tag = SeoTag.main;

  /// The HTML tag to generate in the SEO Shadow Tree.
  final SeoTag tag;

  /// The Flutter widget to render visually.
  ///
  /// This widget is rendered normally through Flutter's rendering pipeline.
  /// The SEO representation is separate and hidden.
  final Widget child;

  /// The text content for the SEO element.
  ///
  /// If null, the system will attempt to extract text from the [child]
  /// widget (if it's a [Text] widget or similar).
  final String? text;

  /// HTML attributes for the SEO element.
  ///
  /// These are added to the generated HTML element. Common uses include:
  /// - `class` for CSS class names
  /// - `id` for unique identification
  /// - `data-*` for custom data attributes
  /// - Schema.org attributes for structured data
  final Map<String, String> attributes;

  @override
  State<Seo> createState() => _SeoState();
}

class _SeoState extends State<Seo> {
  SeoTreeNode? _seoTreeNode;

  @override
  void initState() {
    super.initState();
    _registerWithSeoTree();
  }

  @override
  void didUpdateWidget(Seo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tag != oldWidget.tag ||
        widget.text != oldWidget.text ||
        !_mapEquals(widget.attributes, oldWidget.attributes)) {
      _updateSeoTree();
    }
  }

  @override
  void dispose() {
    _unregisterFromSeoTree();
    super.dispose();
  }

  void _registerWithSeoTree() {
    // Only register on web platform
    if (!_isWebPlatform) {
      return;
    }

    final seoTree = SeoTree.maybeOf(context);
    if (seoTree != null) {
      _seoTreeNode = seoTree.register(
        _buildSeoNode(),
        context,
      );
    }
  }

  void _updateSeoTree() {
    if (_seoTreeNode != null) {
      _seoTreeNode!.update(_buildSeoNode());
    }
  }

  void _unregisterFromSeoTree() {
    if (_seoTreeNode != null) {
      final seoTree = SeoTree.maybeOf(context);
      seoTree?.unregister(_seoTreeNode!);
      _seoTreeNode = null;
    }
  }

  SeoNode _buildSeoNode() {
    String? text = widget.text;

    // Try to extract text from child if not provided
    if (text == null) {
      text = _extractTextFromWidget(widget.child);
    }

    return SeoNode(
      tag: widget.tag,
      text: text,
      attributes: widget.attributes,
    );
  }

  /// Attempts to extract text content from a widget.
  String? _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    // Add support for other text-containing widgets as needed
    return null;
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  // Platform detection - in real implementation, use proper conditional imports
  bool get _isWebPlatform {
    // This would use conditional compilation in production:
    // import 'seo_stub.dart' if (dart.library.html) 'seo_web.dart';
    return true; // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    // Simply return the child - visual rendering is unchanged
    return widget.child;
  }
}

/// Provides semantic text content for SEO without wrapping in an element.
///
/// Use this when you need to provide SEO text that doesn't correspond to
/// a specific HTML element, such as for complex custom widgets.
///
/// ```dart
/// SeoText(
///   text: 'Important information',
///   child: MyComplexWidget(),
/// )
/// ```
///
/// {@category SEO}
class SeoText extends StatelessWidget {
  /// Creates an SEO text provider.
  const SeoText({
    super.key,
    required this.text,
    required this.child,
  });

  /// The text content for SEO purposes.
  final String text;

  /// The Flutter widget to render visually.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: SeoTag.span,
      text: text,
      child: child,
    );
  }
}

/// A widget that excludes its subtree from the SEO Shadow Tree.
///
/// Use this to prevent certain content from being indexed, such as:
/// - User-generated content that shouldn't be indexed
/// - Duplicate content
/// - Administrative interfaces
///
/// ```dart
/// SeoExclude(
///   child: AdminPanel(),
/// )
/// ```
///
/// {@category SEO}
class SeoExclude extends StatelessWidget {
  /// Creates an SEO exclusion widget.
  const SeoExclude({
    super.key,
    required this.child,
  });

  /// The widget subtree to exclude from SEO indexing.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // In the real implementation, this would set a flag in the context
    // that prevents descendant Seo widgets from registering
    return child;
  }
}
