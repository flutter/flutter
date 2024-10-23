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
  });

  final String src;

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
      return createImgElementWidget(widget.src);
    }
  }
}
