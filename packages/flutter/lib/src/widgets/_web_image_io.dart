// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../foundation.dart';
import '../../widgets.dart';

/// Returns [true] if the bytes at [url] can be fetched.
///
/// The bytes may be unable to be fetched if they aren't from the same origin
/// and the sever hosting them does not allow cross-origin requests.
Future<bool> checkIfImageBytesCanBeFetched(String url) {
  // On mobile and desktop there are no cross-origin restrictions.
  return SynchronousFuture<bool>(true);
}

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

class WebImageProviderImpl implements WebImageProvider {
  WebImageProviderImpl(this.src);

  String src;
}

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
