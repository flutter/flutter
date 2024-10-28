// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../widgets.dart';
import '_web_image_io.dart' if (dart.library.js_interop) '_web_image_web.dart';

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
class WebImage extends StatefulWidget {
  /// Creates a web image.
  const WebImage(
    this.src, {
    super.key,
    this.loadingBuilder,
    this.frameBuilder,
    this.errorBuilder,
  });


  /// The URL from which the image will be fetched.
  final String src;


  /// A builder that specifies the widget to display to the user while an image
  /// is still loading.
  ///
  /// See [Image.network] for a fuller description.
  final ImageLoadingBuilder? loadingBuilder;


  /// A builder function responsible for creating the widget that represents
  /// this image.
  ///
  /// See [Image.network] for a fuller description.
  final ImageFrameBuilder? frameBuilder;

  /// A builder function that is called if an error occurs during image loading.
  ///
  /// See [Image.network] for a fuller description.
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<WebImage> createState() => _WebImageState();
}

class _WebImageState extends State<WebImage> {
  bool checkedIfBytesCanBeFetched = false;
  bool imageBytesCanBeFetched = true;
  @override
  void initState() {
    super.initState();
    // Check if `widget.src` can be fetched.
    checkIfImageBytesCanBeFetched(widget.src).then((bool canBeFetched) {
      setState(() {
        checkedIfBytesCanBeFetched = true;
        imageBytesCanBeFetched = canBeFetched;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!checkedIfBytesCanBeFetched) {
      return Container();
    } else if (imageBytesCanBeFetched) {
      return Image.network(widget.src);
    } else {
      return createImgElementWidget(
        widget.src,
        key: widget.key,
        loadingBuilder: widget.loadingBuilder,
        frameBuilder: widget.frameBuilder,
        errorBuilder: widget.errorBuilder,
      );
    }
  }
}
