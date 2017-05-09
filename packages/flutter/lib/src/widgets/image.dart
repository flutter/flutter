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
ImageConfiguration createLocalImageConfiguration(BuildContext context, { Size size }) {
  return new ImageConfiguration(
    bundle: DefaultAssetBundle.of(context),
    devicePixelRatio: MediaQuery.of(context, nullOk: true)?.devicePixelRatio ?? 1.0,
    // TODO(ianh): provide the locale
    size: size,
    platform: Platform.operatingSystem,
  );
}

/// An immutable style for [Image] widgets.
@immutable
class ImageStyle {
  /// Creates an image style.
  const ImageStyle({
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment,
    this.repeat,
    this.centerSlice,
    this.gaplessPlayback
  });

  const ImageStyle.fallback() : this(
    repeat: ImageRepeat.noRepeat,
    gaplessPlayback: false
  );

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

  ImageStyle copyWith({
    double width,
    double height,
    Color color,
    BlendMode colorBlendMode,
    BoxFit fit,
    FractionalOffset alignment,
    ImageRepeat repeat,
    Rect centerSlice,
    bool gaplessPlayback
  }) {
    return new ImageStyle(
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      colorBlendMode: colorBlendMode ?? this.colorBlendMode,
      fit: fit ?? this.fit,
      alignment: alignment ?? this.alignment,
      repeat: repeat ?? this.repeat,
      centerSlice: centerSlice ?? this.centerSlice,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback
    );
  }

  ImageStyle merge(ImageStyle other) {
    if (other == null)
      return this;
    return copyWith(
      width: other.width,
      height: other.height,
      color: other.color,
      colorBlendMode: other.colorBlendMode,
      fit: other.fit,
      alignment: other.alignment,
      repeat: other.repeat,
      centerSlice: other.centerSlice,
      gaplessPlayback: other.gaplessPlayback
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! ImageStyle)
      return false;
    final ImageStyle typedOther = other;
    return width == typedOther.width &&
        height == typedOther.height &&
        color == typedOther.color &&
        colorBlendMode == typedOther.colorBlendMode &&
        fit == typedOther.fit &&
        alignment == typedOther.alignment &&
        repeat == typedOther.repeat &&
        centerSlice == typedOther.centerSlice &&
        gaplessPlayback == typedOther.gaplessPlayback;
  }

  @override
  int get hashCode {
    return hashValues(
      width,
      height,
      color,
      colorBlendMode,
      fit,
      alignment,
      repeat,
      centerSlice,
      gaplessPlayback
    );
  }

  @override
  String toString([String prefix = '']) {
    final List<String> result = <String>[];
    if (width != null)
      result.add('width: $width');
    if (height != null)
      result.add('height: $height');
    if (color != null)
      result.add('color: $color');
    if (colorBlendMode != null)
      result.add('colorBlendMode: $colorBlendMode');
    if (fit != null)
      result.add('fit: $fit');
    if (alignment != null)
      result.add('alignment: $alignment');
    if (repeat != ImageRepeat.noRepeat)
      result.add('repeat: $repeat');
    if (centerSlice != null)
      result.add('centerSlice: $centerSlice');
    return "$prefix${result.join('\n')}";
  }
}

/// The image style to apply to descendant [Image] widgets without explicit style.
class DefaultImageStyle extends InheritedWidget {
  /// Creates a default image style for the given subtree.
  ///
  /// Consider using [DefaultImageStyle.merge] to inherit styling information
  /// from the current default image style for a given [BuildContext].
  /// In the case that [DefaultImageStyle.merge] cannot be used, make sure to
  /// inherit style values from [new ImageStyle.fallback].
  /// This is done automatically for you when you use [DefaultImageStyle.merge].
  const DefaultImageStyle({
    Key key,
    @required this.style,
    @required Widget child,
  }) : assert(style != null),
       assert(child != null),
       super(key: key, child: child);

  /// A const-constructible default image style that provides fallback values.
  ///
  /// Returned from [of] when the given [BuildContext] doesn't have an enclosing default image style.
  ///
  /// This constructor creates a [DefaultImageStyle] that lacks a [child], which
  /// means the constructed value cannot be incorporated into the tree.
  const DefaultImageStyle.fallback()
      : style = const ImageStyle.fallback();

  /// Creates a default image style that overrides the image styles in scope at
  /// this point in the widget tree.
  ///
  /// The given [style] is merged with the [style] from the default image style
  /// for the [BuildContext] where the widget is inserted.
  static Widget merge({
    Key key,
    ImageStyle style,
    @required Widget child,
  }) {
    assert(child != null);
    return new Builder(
      builder: (BuildContext context) {
        final DefaultImageStyle parent = DefaultImageStyle.of(context);
        return new DefaultImageStyle(
          key: key,
          style: parent.style.merge(style),
          child: child
        );
      },
    );
  }

  /// The image style to apply.
  final ImageStyle style;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If no such instance exists, returns an instance created by
  /// [DefaultImageStyle.fallback], which contains fallback values.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DefaultImageStyle style = DefaultImageStyle.of(context);
  /// ```
  static DefaultImageStyle of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DefaultImageStyle) ?? const DefaultImageStyle.fallback();
  }

  @override
  bool updateShouldNotify(DefaultImageStyle old) {
    return style != old.style;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    '$style'.split('\n').forEach(description.add);
  }
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
    this.style: const ImageStyle()
  }) : assert(image != null),
       super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from the network.
  ///
  /// The [src], [scale], and [repeat] arguments must not be null.
  Image.network(String src, {
    Key key,
    double scale: 1.0,
    this.style: const ImageStyle()
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
    this.style: const ImageStyle()
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
    this.style: const ImageStyle()
  }) : image = scale != null ? new ExactAssetImage(name, bundle: bundle, scale: scale)
                             : new AssetImage(name, bundle: bundle),
       super(key: key);

  /// Creates a widget that displays an [ImageStream] obtained from a [Uint8List].
  ///
  /// The [bytes], [scale], and [repeat] arguments must not be null.
  Image.memory(Uint8List bytes, {
    Key key,
    double scale: 1.0,
    this.style: const ImageStyle()
  }) : image = new MemoryImage(bytes, scale: scale),
       super(key: key);

  /// The image to display.
  final ImageProvider image;

  /// The style to give to the image.
  final ImageStyle style;

  @override
  _ImageState createState() => new _ImageState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('image: $image');
    description.add('style: $style');
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
    final ImageStyle style = DefaultImageStyle.of(context)
        .style.merge(widget.style);
    final ImageStream oldImageStream = _imageStream;
    _imageStream = widget.image.resolve(createLocalImageConfiguration(
      context,
      size: style.width != null &&
          style.height != null ?
            new Size(style.width, style.height) : null
    ));
    assert(_imageStream != null);
    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      if (!style.gaplessPlayback)
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
    final ImageStyle style = DefaultImageStyle.of(context)
        .style.merge(widget.style);
    return new RawImage(
      image: _imageInfo?.image,
      width: style.width,
      height: style.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: style.color,
      colorBlendMode: style.colorBlendMode,
      fit: style.fit,
      alignment: style.alignment,
      repeat: style.repeat,
      centerSlice: style.centerSlice
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('stream: $_imageStream');
    description.add('pixels: $_imageInfo');
  }
}
