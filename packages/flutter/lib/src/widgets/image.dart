// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

export 'package:flutter/services.dart' show
  ImageProvider,
  AssetImage,
  ExactAssetImage,
  MemoryImage,
  NetworkImage,
  FileImage;

/// Creates an [ImageConfiguration] based on the given [BuildContext] (and
/// optionally size).
///
/// This is the object that must be passed to [BoxPainter.paint] and to
/// [ImageProvider.resolve].
///
/// If this is not called from a build method, then it should be reinvoked
/// whenever the dependencies change, e.g. by calling it from
/// [State.didChangeDependencies], so that any changes in the environement are
/// picked up (e.g. if the device pixel ratio changes).
///
/// See also:
///
///  * [ImageProvider], which has an example showing how this might be used.
ImageConfiguration createLocalImageConfiguration(BuildContext context, { Size size }) {
  return new ImageConfiguration(
    bundle: DefaultAssetBundle.of(context),
    devicePixelRatio: MediaQuery.of(context, nullOk: true)?.devicePixelRatio ?? 1.0,
    // TODO(ianh): provide the locale
    size: size,
    platform: Platform.operatingSystem,
  );
}

/// A widget that displays an image.
///
/// Several constructors are provided for the various ways that an image can be
/// specified:
///
///  * [new Image], for obtaining an image from an [ImageProvider].
///  * [new Image.asset], for obtaining an image from an [AssetBundle]
///    using a key.
///  * [new Image.network], for obtaining an image from a URL.
///  * [new Image.file], for obtaining an image from a [File].
///  * [new Image.memory], for obtaining an image from a [Uint8List].
///
/// To automatically perform pixel-density-aware asset resolution, specify the
/// image using an [AssetImage] and make sure that a [MaterialApp], [WidgetsApp],
/// or [MediaQuery] widget exists above the [Image] widget in the widget tree.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
///
/// See also:
///
///  * [Icon]
class Image extends StatefulWidget {
  /// Creates a widget that displays an image.
  ///
  /// To show an image from the network or from an asset bundle, consider using
  /// [new Image.network] and [new Image.asset] respectively.
  ///
  /// The [image] and [repeat] arguments must not be null.
  const Image({
    Key key,
    @required this.image,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.gaplessPlayback: false
  }) : assert(image != null),
       super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from the network.
  ///
  /// The [src], [scale], and [repeat] arguments must not be null.
  Image.network(String src, {
    Key key,
    double scale: 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.gaplessPlayback: false
  }) : image = new NetworkImage(src, scale: scale),
       super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from a [File].
  ///
  /// The [file], [scale], and [repeat] arguments must not be null.
  ///
  /// On Android, this may require the
  /// `android.permission.READ_EXTERNAL_STORAGE` permission.
  Image.file(File file, {
    Key key,
    double scale: 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.gaplessPlayback: false
  }) : image = new FileImage(file, scale: scale),
       super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from an asset
  /// bundle. The key for the image is given by the `name` argument.
  ///
  /// If the `bundle` argument is omitted or null, then the
  /// [DefaultAssetBundle] will be used.
  ///
  /// If the `scale` argument is omitted or null, then pixel-density-aware asset
  /// resolution will be attempted.
  ///
  /// If [width] and [height] are both specified, and [scale] is not, then
  /// size-aware asset resolution will be attempted also.
  ///
  /// The [name] and [repeat] arguments must not be null.
  Image.asset(String name, {
    Key key,
    AssetBundle bundle,
    double scale,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.gaplessPlayback: false
  }) : image = scale != null ? new ExactAssetImage(name, bundle: bundle, scale: scale)
                             : new AssetImage(name, bundle: bundle),
       super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from a [Uint8List].
  ///
  /// The [bytes], [scale], and [repeat] arguments must not be null.
  Image.memory(Uint8List bytes, {
    Key key,
    double scale: 1.0,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.gaplessPlayback: false
  }) : image = new MemoryImage(bytes, scale: scale),
       super(key: key);

  /// The image to display.
  final ImageProvider image;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode colorBlendMode;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  /// Whether to continue showing the old image (true), or briefly show nothing
  /// (false), when the image provider changes.
  final bool gaplessPlayback;

  @override
  _ImageState createState() => new _ImageState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('image: $image');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
    if (color != null)
      description.add('color: $color');
    if (colorBlendMode != null)
      description.add('colorBlendMode: $colorBlendMode');
    if (fit != null)
      description.add('fit: $fit');
    if (alignment != null)
      description.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      description.add('repeat: $repeat');
    if (centerSlice != null)
      description.add('centerSlice: $centerSlice');
  }
}

class _ImageState extends State<Image> {
  ImageStream _imageStream;
  ImageInfo _imageInfo;

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image)
      _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = widget.image.resolve(createLocalImageConfiguration(
      context,
      size: widget.width != null && widget.height != null ? new Size(widget.width, widget.height) : null
    ));
    assert(_imageStream != null);
    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      if (!widget.gaplessPlayback)
        setState(() { _imageInfo = null; });
      _imageStream.addListener(_handleImageChanged);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
    });
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    _imageStream.removeListener(_handleImageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('stream: $_imageStream');
    description.add('pixels: $_imageInfo');
  }
}
