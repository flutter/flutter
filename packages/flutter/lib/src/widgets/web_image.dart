// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'image.dart';

/// A widget that displays an image from the web.
///
/// Due to restrictions on cross-origin images on the web, in cases where the
/// image [url] is cross-origin and access to the byte data is disallowed, this
/// widget will instead use a platform view to display the image in an `<img>`
/// element.
///
/// If the [src] of the image is same-origin, or if we are able to make a
/// cross-origin request for the image bytes, then this widget works exactly
/// the same as [Image.network].
class WebImage extends StatelessWidget {

  /// Creates a web image.
  const WebImage(
    this.src, {
    super.key,
    this.scale = 1.0,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.headers,
    this.cacheWidth,
    this.cacheHeight,
  })  : assert(cacheWidth == null || cacheWidth > 0),
        assert(cacheHeight == null || cacheHeight > 0);

  final String src;

  final double scale;

  final ImageFrameBuilder? frameBuilder;

  final ImageLoadingBuilder? loadingBuilder;

  final ImageErrorWidgetBuilder? errorBuilder;

  final String? semanticLabel;

  final bool excludeFromSemantics;

  final double? width;

  final double? height;

  final Color? color;

  final Animation<double>? opacity;

  final BlendMode? colorBlendMode;

  final BoxFit? fit;

  final Alignment alignment;

  final ImageRepeat repeat;

  final Rect? centerSlice;

  final bool matchTextDirection;

  final bool gaplessPlayback;

  final FilterQuality filterQuality;

  final bool isAntiAlias;

  final Map<String, String>? headers;

  final int? cacheWidth;

  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    return Image.network(src,
      key: key,
      scale: scale,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      isAntiAlias: isAntiAlias,
      headers: headers,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}
