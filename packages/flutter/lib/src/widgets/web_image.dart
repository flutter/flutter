// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../widgets.dart';
import '_web_image_io.dart' if (dart.library.js_interop) '_web_image_web.dart'
    as impl;

/// A substitute for [Image.network] that follows the web's [same origin policy][].
///
/// On mobile this widget delegates to [Image.network]. On the web this widget
/// delegates to [Image.network] if the server allows fetching the image using
/// a XHR. Otherwise, it uses an `<img>` element to display the image.
///
/// If the [src] of the image is same-origin, or if a HEAD request for [src]
/// indicates that a GET request would succeed, then this widget works exactly
/// the same as [Image.network].
///
/// # Multi-frame Images
///
/// In the case that the [src] can't be fetched directly and a platform view is
/// used to display the image, then if the [src] points to a multi-frame image
/// (e.g. an animated GIF), then there is no way to control the display of the
/// frames of the image. For example, if [src] points to an animated GIF, this
/// widget will just play the GIF animation.
///
/// # Performance Implications
///
/// Rendering many platform views can be a performance burden. Flutter attempts
/// to optimize platform view rendering, but cannot do so in all cases. It is
/// difficult for Flutter to optimize platform views in cases where other
/// content is rendered on top of multiple platform views, so consider laying
/// out [WebImage] widgets so there are no other widgets drawn on top of them.
///
/// # Usage Guidelines
///
/// When possible, consider using an [Image.network] widget instead of
/// [WebImage]. If you control the server hosting the images you want to
/// display, consider configuring the server to support cross-origin requests
/// to enable [Image.network].
///
/// [same origin policy]: https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy
class WebImage extends StatefulWidget {
  /// Creates a web image with the given [image].
  const WebImage({
    required this.image,
    super.key,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
  });

  /// Creates a web image showing the image at the URL [src].
  WebImage.network(
    String src, {
    super.key,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
  }) : image = WebImageProvider(src);

  /// The resource which provides the image.
  final WebImageProvider image;

  /// {@macro flutter.widgets.Image.loadingBuilder}
  final ImageLoadingBuilder? loadingBuilder;

  /// A builder function responsible for creating the widget that represents
  /// this image.
  ///
  /// See [Image.frameBuilder].
  final ImageFrameBuilder? frameBuilder;

  /// {@macro flutter.widgets.Image.errorBuilder}
  final ImageErrorWidgetBuilder? errorBuilder;

  /// {@macro flutter.widgets.Image.semanticLabel}
  final String? semanticLabel;

  /// {@macro flutter.widgets.Image.excludeFromSemantics}
  final bool excludeFromSemantics;

  /// {@macro flutter.widgets.Image.width}
  final double? width;

  /// {@macro flutter.widgets.Image.height}
  final double? height;

  /// {@macro flutter.widgets.Image.fit}
  final BoxFit? fit;

  /// {@macro flutter.widgets.Image.alignment}
  final AlignmentGeometry alignment;

  /// {@macro flutter.widgets.Image.matchTextDirection}
  final bool matchTextDirection;

  /// {@macro flutter.widgets.Image.gaplessPlayback}
  final bool gaplessPlayback;

  @override
  State<WebImage> createState() => impl.WebImageState();
}

/// If the [provider] points to a web image resource that can be directly
/// fetched, then this calls [precacheImage] with the resource URL as the
/// provider. Otherwise, this completes when the underlying image resource
/// has been decoded and is ready to display in an <img> element.
Future<void> precacheWebImage(
  WebImageProvider provider,
  BuildContext context, {
  Size? size,
  ImageErrorListener? onError,
}) =>
    impl.precacheWebImage(provider, context, size: size, onError: onError);

/// A key for loading the web image resource located at the URL [src].
abstract class WebImageProvider {
  /// Creates a new [WebImageProvider].
  factory WebImageProvider(String src) => impl.WebImageProviderImpl(src);

  /// The URL the web image resource is located at.
  String get src;
}
