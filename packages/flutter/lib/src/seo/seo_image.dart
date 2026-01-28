// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'seo_tag.dart';
import 'seo_widget.dart';

/// A widget that creates a semantic image for SEO purposes.
///
/// [SeoImage] generates both:
/// 1. A visual Flutter Image widget
/// 2. A hidden `<img>` element with proper `alt` text in the SEO Shadow Tree
///
/// ## Basic Usage
///
/// ```dart
/// SeoImage(
///   src: 'https://example.com/product.jpg',
///   alt: 'Red running shoes - Nike Air Max',
///   child: Image.network('https://example.com/product.jpg'),
/// )
/// ```
///
/// ## With Network Image
///
/// ```dart
/// SeoImage.network(
///   'https://example.com/hero.jpg',
///   alt: 'Beautiful sunset over the ocean',
///   width: 1200,
///   height: 800,
/// )
/// ```
///
/// ## With Asset Image
///
/// ```dart
/// SeoImage.asset(
///   'assets/images/logo.png',
///   alt: 'Company Logo',
///   width: 200,
///   height: 50,
/// )
/// ```
///
/// {@category SEO}
class SeoImage extends StatelessWidget {
  /// Creates an SEO-enabled image widget.
  const SeoImage({
    super.key,
    required this.src,
    required this.alt,
    required this.child,
    this.width,
    this.height,
    this.loading = SeoImageLoading.lazy,
    this.title,
  });

  /// Creates an SEO-enabled network image.
  ///
  /// This is a convenience constructor that creates both the SEO metadata
  /// and the visual Image.network widget.
  factory SeoImage.network(
    String src, {
    Key? key,
    required String alt,
    int? width,
    int? height,
    SeoImageLoading loading = SeoImageLoading.lazy,
    String? title,
    BoxFit? fit,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    return SeoImage(
      key: key,
      src: src,
      alt: alt,
      width: width,
      height: height,
      loading: loading,
      title: title,
      child: Image.network(
        src,
        width: width?.toDouble(),
        height: height?.toDouble(),
        fit: fit,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
      ),
    );
  }

  /// Creates an SEO-enabled asset image.
  ///
  /// Note: For asset images, the [src] should be the public URL where
  /// the image will be accessible after deployment, not the asset path.
  factory SeoImage.asset(
    String assetPath, {
    Key? key,
    required String alt,
    String? publicSrc,
    int? width,
    int? height,
    SeoImageLoading loading = SeoImageLoading.lazy,
    String? title,
    BoxFit? fit,
  }) {
    return SeoImage(
      key: key,
      // Use public URL if provided, otherwise use asset path
      // (which may not be accessible to crawlers)
      src: publicSrc ?? assetPath,
      alt: alt,
      width: width,
      height: height,
      loading: loading,
      title: title,
      child: Image.asset(assetPath, width: width?.toDouble(), height: height?.toDouble(), fit: fit),
    );
  }

  /// The URL of the image.
  ///
  /// This should be the public URL that search engines can access.
  final String src;

  /// The alternative text for the image.
  ///
  /// This is crucial for:
  /// - Search engine image indexing
  /// - Accessibility (screen readers)
  /// - Display when image fails to load
  ///
  /// Best practices:
  /// - Be descriptive and specific
  /// - Keep it concise (typically under 125 characters)
  /// - Don't start with "Image of" or "Picture of"
  /// - Include relevant keywords naturally
  final String alt;

  /// The Flutter widget to render visually.
  final Widget child;

  /// The display width of the image in pixels.
  ///
  /// Specifying dimensions helps prevent layout shift and improves
  /// Core Web Vitals scores.
  final int? width;

  /// The display height of the image in pixels.
  final int? height;

  /// The loading behavior for the image.
  ///
  /// - [SeoImageLoading.lazy] - Load when near viewport (recommended)
  /// - [SeoImageLoading.eager] - Load immediately (for above-fold images)
  final SeoImageLoading loading;

  /// Optional title text shown on hover.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: SeoTag.img,
      attributes: {
        'src': src,
        'alt': alt,
        if (width != null) 'width': width.toString(),
        if (height != null) 'height': height.toString(),
        'loading': loading.value,
        if (title != null) 'title': title!,
      },
      child: child,
    );
  }
}

/// Loading behavior for SEO images.
enum SeoImageLoading {
  /// Load the image when it enters the viewport.
  ///
  /// This is the recommended default for most images as it improves
  /// initial page load performance.
  lazy,

  /// Load the image immediately.
  ///
  /// Use this for above-the-fold images that are visible without scrolling,
  /// such as hero images or the first content image.
  eager,
}

extension on SeoImageLoading {
  String get value {
    switch (this) {
      case SeoImageLoading.lazy:
        return 'lazy';
      case SeoImageLoading.eager:
        return 'eager';
    }
  }
}

/// A widget that creates a figure with an optional caption for SEO.
///
/// Wraps an image (or other content) in a `<figure>` element with an
/// optional `<figcaption>`.
///
/// ```dart
/// SeoFigure(
///   caption: 'Chart showing quarterly revenue growth',
///   child: SeoImage.network(
///     'https://example.com/chart.png',
///     alt: 'Bar chart showing Q1-Q4 revenue',
///   ),
/// )
/// ```
///
/// {@category SEO}
class SeoFigure extends StatelessWidget {
  /// Creates an SEO figure widget.
  const SeoFigure({
    super.key,
    required this.child,
    this.caption,
    this.captionPosition = SeoCaptionPosition.bottom,
  });

  /// The content of the figure (typically an image).
  final Widget child;

  /// The caption text for the figure.
  final String? caption;

  /// Where to position the caption relative to the content.
  final SeoCaptionPosition captionPosition;

  @override
  Widget build(BuildContext context) {
    final captionWidget = caption != null
        ? Seo(
            tag: SeoTag.figcaption,
            text: caption,
            child: Text(
              caption!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          )
        : null;

    return Seo(
      tag: SeoTag.figure,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (captionWidget != null && captionPosition == SeoCaptionPosition.top) captionWidget,
          child,
          if (captionWidget != null && captionPosition == SeoCaptionPosition.bottom) captionWidget,
        ],
      ),
    );
  }
}

/// Position of a figure caption.
enum SeoCaptionPosition {
  /// Caption appears above the content.
  top,

  /// Caption appears below the content.
  bottom,
}
