import 'package:flutter/widgets.dart';

import '../octo_set.dart';
import 'image_handler.dart';

typedef OctoImageBuilder = Widget Function(BuildContext context, Widget child);
typedef OctoPlaceholderBuilder = Widget Function(BuildContext context);
typedef OctoProgressIndicatorBuilder = Widget Function(
  BuildContext context,
  ImageChunkEvent? progress,
);
typedef OctoErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// OctoImage can be used as a replacement of [Image]. It can be used with any
/// [ImageProvider], but works best with [CachedNetworkImageProvider](https://pub.dev/packages/cached_network_image).
/// OctoImage can show a placeholder or progress and an error. It can also do
/// transformations on the shown image.
/// This all can be simplified by using a complete [OctoSet] with predefined
/// combinations of [OctoPlaceholderBuilder], [OctoImageBuilder] and
/// [OctoErrorBuilder].
class OctoImage extends StatefulWidget {
  /// The image that should be shown.
  final ImageProvider image;

  /// Optional builder to further customize the display of the image.
  final OctoImageBuilder? imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final OctoPlaceholderBuilder? placeholderBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final OctoProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final OctoErrorBuilder? errorBuilder;

  /// The duration of the fade-in animation for the [placeholderBuilder].
  final Duration placeholderFadeInDuration;

  /// The duration of the fade-out animation for the [placeholderBuilder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholderBuilder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [imageUrl].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [imageUrl].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while
  /// a [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn
  /// with a scaling factor of -1 in the horizontal direction so that the origin
  /// is in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// If non-null, this color is blended with each image pixel using
  /// [colorBlendMode].
  final Color? color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each
  ///  blend mode.
  final BlendMode? colorBlendMode;

  /// Target the interpolation quality for image scaling.
  ///
  /// If not given a value, defaults to FilterQuality.low.
  final FilterQuality filterQuality;

  /// Whether to continue showing the old image (true), or briefly show the
  /// placeholder (false), when the image provider changes.
  final bool gaplessPlayback;

  /// Creates an OctoWidget that displays an image. The [image] is an
  /// ImageProvider and the OctoImage should work with any [ImageProvider].
  /// The widget is optimized for [CachedNetworkImageProvider](https://pub.dev/packages/cached_network_image) or
  /// [NetworkImage], as for those it makes sense to show download progress
  /// or an error widget.
  ///
  /// The [placeholderBuilder] or [progressIndicatorBuilder] can be set to show
  /// a placeholder widget. At most one of these two should be set. The
  /// [progressIndicatorBuilder] is called every time new progress information
  /// is available, so if you don't use that progress info in your widget you
  /// should use [placeholderBuilder] which is not called so often.
  ///
  /// The [imageBuilder] can be used for image transformations after the image
  /// is loaded.
  ///
  /// When the [image] failed loading the [errorBuilder] is called with the
  /// error and stacktrace. This can be used to show an error widget.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  ///
  /// Use [filterQuality] to change the quality when scaling an image.
  /// Use the [FilterQuality.low] quality setting to scale the image,
  /// which corresponds to bilinear interpolation, rather than the default
  /// [FilterQuality.none] which corresponds to nearest-neighbor.
  ///
  /// If [excludeFromSemantics] is true, then [semanticLabel] will be ignored.
  ///
  /// If [memCacheWidth] or [memCacheHeight] are provided, it indicates to the
  /// engine that the image must be decoded at the specified size. The image
  /// will be rendered to the constraints of the layout or [width] and [height]
  /// regardless of these parameters. These parameters are primarily intended
  /// to reduce the memory usage of [ImageCache].
  OctoImage({
    Key? key,
    required ImageProvider image,
    this.imageBuilder,
    this.placeholderBuilder,
    this.progressIndicatorBuilder,
    this.errorBuilder,
    Duration? fadeOutDuration,
    Curve? fadeOutCurve,
    Duration? fadeInDuration,
    Curve? fadeInCurve,
    this.width,
    this.height,
    this.fit,
    Alignment? alignment,
    ImageRepeat? repeat,
    bool? matchTextDirection,
    this.color,
    FilterQuality? filterQuality,
    this.colorBlendMode,
    Duration? placeholderFadeInDuration,
    bool? gaplessPlayback,
    int? memCacheWidth,
    int? memCacheHeight,
  })  : image = ResizeImage.resizeIfNeeded(
          memCacheWidth,
          memCacheHeight,
          image,
        ),
        fadeOutDuration = fadeOutDuration ?? const Duration(milliseconds: 1000),
        fadeOutCurve = fadeOutCurve ?? Curves.easeOut,
        fadeInDuration = fadeInDuration ?? const Duration(milliseconds: 500),
        fadeInCurve = fadeInCurve ?? Curves.easeIn,
        alignment = alignment ?? Alignment.center,
        repeat = repeat ?? ImageRepeat.noRepeat,
        matchTextDirection = matchTextDirection ?? false,
        filterQuality = filterQuality ?? FilterQuality.low,
        placeholderFadeInDuration = placeholderFadeInDuration ?? Duration.zero,
        gaplessPlayback = gaplessPlayback ?? false,
        super(key: key);

  /// Creates an OctoWidget that displays an image with a predefined [OctoSet].
  /// The [image] is an ImageProvider and the OctoImage should work with any
  /// [ImageProvider]. The widget is optimized for [CachedNetworkImageProvider](https://pub.dev/packages/cached_network_image).
  /// or [NetworkImage], as for those it makes sense to show download progress
  /// or an error widget.
  ///
  /// The [octoSet] should be set and contains all the information for the
  /// placeholder, error and image transformations.
  ///
  /// When the [image] failed loading the [errorBuilder] is called with the
  /// error and stacktrace. This can be used to show an error widget.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  ///
  /// Use [filterQuality] to change the quality when scaling an image.
  /// Use the [FilterQuality.low] quality setting to scale the image,
  /// which corresponds to bilinear interpolation, rather than the default
  /// [FilterQuality.none] which corresponds to nearest-neighbor.
  ///
  /// If [excludeFromSemantics] is true, then [semanticLabel] will be ignored.
  ///
  /// If [memCacheWidth] or [memCacheHeight] are provided, it indicates to the
  /// engine that the image must be decoded at the specified size. The image
  /// will be rendered to the constraints of the layout or [width] and [height]
  /// regardless of these parameters. These parameters are primarily intended
  /// to reduce the memory usage of [ImageCache].
  OctoImage.fromSet({
    Key? key,
    required ImageProvider image,
    required OctoSet octoSet,
    Duration? fadeOutDuration,
    Curve? fadeOutCurve,
    Duration? fadeInDuration,
    Curve? fadeInCurve,
    this.width,
    this.height,
    this.fit,
    Alignment? alignment,
    ImageRepeat? repeat,
    bool? matchTextDirection,
    this.color,
    FilterQuality? filterQuality,
    this.colorBlendMode,
    Duration? placeholderFadeInDuration,
    bool? gaplessPlayback,
    int? memCacheWidth,
    int? memCacheHeight,
  })  : image = ResizeImage.resizeIfNeeded(
          memCacheWidth,
          memCacheHeight,
          image,
        ),
        imageBuilder = octoSet.imageBuilder,
        placeholderBuilder = octoSet.placeholderBuilder,
        progressIndicatorBuilder = octoSet.progressIndicatorBuilder,
        errorBuilder = octoSet.errorBuilder,
        fadeOutDuration = fadeOutDuration ?? const Duration(milliseconds: 1000),
        fadeOutCurve = fadeOutCurve ?? Curves.easeOut,
        fadeInDuration = fadeInDuration ?? const Duration(milliseconds: 500),
        fadeInCurve = fadeInCurve ?? Curves.easeIn,
        alignment = alignment ?? Alignment.center,
        repeat = repeat ?? ImageRepeat.noRepeat,
        matchTextDirection = matchTextDirection ?? false,
        filterQuality = filterQuality ?? FilterQuality.low,
        placeholderFadeInDuration = placeholderFadeInDuration ?? Duration.zero,
        gaplessPlayback = gaplessPlayback ?? false,
        super(key: key);

  @override
  _OctoImageState createState() => _OctoImageState();
}

class _OctoImageState extends State<OctoImage> {
  ImageHandler? _previousHandler;
  late ImageHandler _imageHandler;

  @override
  void initState() {
    super.initState();
    _imageHandler = ImageHandler(
      image: widget.image,
      imageBuilder: widget.imageBuilder,
      placeholderBuilder: widget.placeholderBuilder,
      progressIndicatorBuilder: widget.progressIndicatorBuilder,
      errorBuilder: widget.errorBuilder,
      placeholderFadeInDuration: widget.placeholderFadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
      fadeOutCurve: widget.fadeOutCurve,
      fadeInDuration: widget.fadeInDuration,
      fadeInCurve: widget.fadeInCurve,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      repeat: widget.repeat,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      matchTextDirection: widget.matchTextDirection,
      filterQuality: widget.filterQuality,
      alwaysShowPlaceHolder: false,
    );
  }

  @override
  void didUpdateWidget(OctoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      if (widget.gaplessPlayback) {
        _previousHandler = _imageHandler;
        _previousHandler?.alwaysShowPlaceHolder = false;
      } else {
        _previousHandler = null;
      }
    }
    _imageHandler = ImageHandler(
      image: widget.image,
      imageBuilder: widget.imageBuilder,
      placeholderBuilder: _previousHandler != null
          ? _previousHandler!.build
          : widget.placeholderBuilder,
      progressIndicatorBuilder:
          _previousHandler != null ? null : widget.progressIndicatorBuilder,
      errorBuilder: widget.errorBuilder,
      placeholderFadeInDuration: widget.placeholderFadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
      fadeOutCurve: widget.fadeOutCurve,
      fadeInDuration: widget.fadeInDuration,
      fadeInCurve: widget.fadeInCurve,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      repeat: widget.repeat,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      matchTextDirection: widget.matchTextDirection,
      filterQuality: widget.filterQuality,
      alwaysShowPlaceHolder: _previousHandler != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _imageHandler.build(context),
    );
  }
}
