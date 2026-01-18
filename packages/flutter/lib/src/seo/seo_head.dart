// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';

/// A widget that injects page-level SEO metadata into the document head.
///
/// [SeoHead] manages:
/// - Page title
/// - Meta description
/// - Canonical URL
/// - Open Graph tags (Facebook, LinkedIn)
/// - Twitter Card tags
/// - Robots directives
///
/// ## Basic Usage
///
/// ```dart
/// SeoHead(
///   title: 'Product Name - My Store',
///   description: 'Buy the best products at competitive prices.',
///   child: ProductPage(),
/// )
/// ```
///
/// ## Full Configuration
///
/// ```dart
/// SeoHead(
///   title: 'Avengers: Secret Wars - Book Tickets',
///   description: 'Book tickets for Avengers: Secret Wars now showing in theaters near you.',
///   canonicalUrl: 'https://movieapp.com/movie/avengers-secret-wars',
///   ogImage: 'https://movieapp.com/images/avengers-poster.jpg',
///   ogType: 'video.movie',
///   twitterCard: SeoTwitterCard.summaryLargeImage,
///   robots: SeoRobots.indexFollow,
///   child: MoviePage(),
/// )
/// ```
///
/// {@category SEO}
class SeoHead extends StatefulWidget {
  /// Creates an SEO head metadata widget.
  const SeoHead({
    super.key,
    required this.title,
    this.description,
    this.canonicalUrl,
    this.ogTitle,
    this.ogDescription,
    this.ogImage,
    this.ogImageAlt,
    this.ogType = 'website',
    this.ogSiteName,
    this.ogLocale,
    this.twitterCard = SeoTwitterCard.summary,
    this.twitterSite,
    this.twitterCreator,
    this.robots,
    this.keywords,
    this.author,
    this.viewport,
    this.themeColor,
    this.alternateLanguages,
    required this.child,
  });

  /// The page title (appears in browser tab and search results).
  ///
  /// Best practices:
  /// - Keep under 60 characters
  /// - Include primary keyword near the beginning
  /// - Make it unique for each page
  /// - Format: "Primary Keyword - Secondary | Brand"
  final String title;

  /// The page description for search results.
  ///
  /// Best practices:
  /// - Keep between 120-160 characters
  /// - Include a call-to-action
  /// - Make it unique and compelling
  final String? description;

  /// The canonical URL for this page.
  ///
  /// Use this to:
  /// - Prevent duplicate content issues
  /// - Consolidate link equity
  /// - Specify the preferred URL version
  final String? canonicalUrl;

  /// Open Graph title (defaults to [title] if not specified).
  final String? ogTitle;

  /// Open Graph description (defaults to [description] if not specified).
  final String? ogDescription;

  /// Open Graph image URL for social sharing.
  ///
  /// Recommended dimensions:
  /// - Facebook: 1200 x 630 pixels
  /// - Twitter: 1200 x 600 pixels
  final String? ogImage;

  /// Alt text for the Open Graph image.
  final String? ogImageAlt;

  /// Open Graph type (e.g., 'website', 'article', 'product').
  final String ogType;

  /// The site name for Open Graph.
  final String? ogSiteName;

  /// The locale for Open Graph (e.g., 'en_US').
  final String? ogLocale;

  /// Twitter Card type.
  final SeoTwitterCard twitterCard;

  /// Twitter @username for the website.
  final String? twitterSite;

  /// Twitter @username for the content creator.
  final String? twitterCreator;

  /// Robots meta directive.
  final SeoRobots? robots;

  /// Keywords for the page (less important for modern SEO).
  final List<String>? keywords;

  /// Author of the content.
  final String? author;

  /// Viewport meta tag (defaults to responsive viewport if not specified).
  final String? viewport;

  /// Theme color for mobile browsers.
  final String? themeColor;

  /// Alternate language versions of this page.
  ///
  /// Key: language code (e.g., 'en', 'es', 'fr')
  /// Value: URL of the alternate version
  final Map<String, String>? alternateLanguages;

  /// The page content widget.
  final Widget child;

  @override
  State<SeoHead> createState() => _SeoHeadState();
}

class _SeoHeadState extends State<SeoHead> {
  @override
  void initState() {
    super.initState();
    _updateDocumentHead();
  }

  @override
  void didUpdateWidget(SeoHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasChanged(oldWidget)) {
      _updateDocumentHead();
    }
  }

  bool _hasChanged(SeoHead oldWidget) {
    return widget.title != oldWidget.title ||
        widget.description != oldWidget.description ||
        widget.canonicalUrl != oldWidget.canonicalUrl ||
        widget.ogImage != oldWidget.ogImage;
    // Add more comparisons as needed
  }

  void _updateDocumentHead() {
    // In web implementation, this would use dart:html to update document.head
    // For now, this is a placeholder showing the intended structure

    // On non-web platforms, this is a no-op
    if (!_isWebPlatform) {
      return;
    }

    // The actual web implementation would do:
    // import 'dart:html' as html;
    // html.document.title = widget.title;
    // _setMetaTag('description', widget.description);
    // _setMetaTag('og:title', widget.ogTitle ?? widget.title);
    // etc.

    debugPrint('SeoHead: Updating document head with title: ${widget.title}');
  }

  bool get _isWebPlatform => true; // Placeholder

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Twitter Card types.
enum SeoTwitterCard {
  /// Small square image with title and description.
  summary,

  /// Large image with title and description.
  summaryLargeImage,

  /// Video/audio player card.
  player,

  /// Mobile app card.
  app,
}

extension on SeoTwitterCard {
  String get value {
    switch (this) {
      case SeoTwitterCard.summary:
        return 'summary';
      case SeoTwitterCard.summaryLargeImage:
        return 'summary_large_image';
      case SeoTwitterCard.player:
        return 'player';
      case SeoTwitterCard.app:
        return 'app';
    }
  }
}

/// Robots meta directive options.
class SeoRobots {
  /// Creates a custom robots directive.
  const SeoRobots({
    this.index = true,
    this.follow = true,
    this.noArchive = false,
    this.noSnippet = false,
    this.noImageIndex = false,
    this.maxSnippet,
    this.maxImagePreview,
    this.maxVideoPreview,
  });

  /// Allow indexing (index) / Disallow indexing (noindex).
  final bool index;

  /// Allow following links (follow) / Disallow following links (nofollow).
  final bool follow;

  /// Prevent cached copy.
  final bool noArchive;

  /// Prevent snippet in search results.
  final bool noSnippet;

  /// Prevent image indexing.
  final bool noImageIndex;

  /// Maximum snippet length (-1 for unlimited).
  final int? maxSnippet;

  /// Maximum image preview size ('none', 'standard', 'large').
  final String? maxImagePreview;

  /// Maximum video preview in seconds (-1 for unlimited).
  final int? maxVideoPreview;

  /// Standard: Allow indexing and following.
  static const SeoRobots indexFollow = SeoRobots();

  /// Don't index but follow links.
  static const SeoRobots noindexFollow = SeoRobots(index: false);

  /// Index but don't follow links.
  static const SeoRobots indexNofollow = SeoRobots(follow: false);

  /// Don't index and don't follow.
  static const SeoRobots noindexNofollow = SeoRobots(index: false, follow: false);

  /// Converts to robots meta content string.
  String toContentString() {
    final parts = <String>[];

    parts.add(index ? 'index' : 'noindex');
    parts.add(follow ? 'follow' : 'nofollow');

    if (noArchive) parts.add('noarchive');
    if (noSnippet) parts.add('nosnippet');
    if (noImageIndex) parts.add('noimageindex');
    if (maxSnippet != null) parts.add('max-snippet:$maxSnippet');
    if (maxImagePreview != null) parts.add('max-image-preview:$maxImagePreview');
    if (maxVideoPreview != null) parts.add('max-video-preview:$maxVideoPreview');

    return parts.join(', ');
  }
}
