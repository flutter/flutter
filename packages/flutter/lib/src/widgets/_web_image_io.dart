// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../foundation.dart';
import '../../widgets.dart';

/// Returns [true] if the bytes at [url] can be fetched.
///
/// The bytes may be unable to be fetched if they aren't from the same origin
/// and the server hosting them does not allow cross-origin requests.
Future<bool> checkIfImageBytesCanBeFetched(String url) {
  // On mobile and desktop there are no cross-origin restrictions.
  return SynchronousFuture<bool>(true);
}

/// The underlying State widget for [WebImage].
class WebImageState extends State<WebImage> {
  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.provider.src,
      frameBuilder: widget.frameBuilder,
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
      semanticLabel: widget.semanticLabel,
      excludeFromSemantics: widget.excludeFromSemantics,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      matchTextDirection: widget.matchTextDirection,
      gaplessPlayback: widget.gaplessPlayback,
    );
  }
}

/// A key for loading the web image resource located at the URL [src].
class WebImageProviderImpl implements WebImageProvider {
  /// Creates a new web image resource located at [src].
  WebImageProviderImpl(this.src);

  /// The URL of the web image resource.
  @override
  final String src;
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
    precacheImage(
      NetworkImage(provider.src),
      context,
      size: size,
      onError: onError,
    );
