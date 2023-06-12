import 'package:flutter/widgets.dart';

import '../../octo_image.dart';
import 'fade_widget.dart';

enum _PlaceholderType {
  none,
  static,
  progress,
}

class ImageHandler {
  /// The image that should be shown.
  final ImageProvider image;

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

  late _PlaceholderType _placeholderType;

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

  /// Indicates that placeholder should always be shown, even if the image
  /// was loaded in the first frame.
  bool alwaysShowPlaceHolder;

  ImageHandler({
    required this.image,
    required this.width,
    required this.height,
    required this.fit,
    required this.alignment,
    required this.repeat,
    required this.matchTextDirection,
    required this.color,
    required this.colorBlendMode,
    required this.filterQuality,
    required this.imageBuilder,
    required this.placeholderBuilder,
    required this.progressIndicatorBuilder,
    required this.errorBuilder,
    required this.placeholderFadeInDuration,
    required this.fadeOutDuration,
    required this.fadeOutCurve,
    required this.fadeInDuration,
    required this.fadeInCurve,
    required this.alwaysShowPlaceHolder,
  }) {
    _placeholderType = _definePlaceholderType();
  }

  ImageFrameBuilder imageFrameBuilder() {
    switch (_placeholderType) {
      case _PlaceholderType.none:
        return _imageBuilder;
      case _PlaceholderType.static:
        return _placeholderBuilder;
      case _PlaceholderType.progress:
        return _preLoadingBuilder;
    }
  }

  ImageLoadingBuilder? imageLoadingBuilder() {
    return _placeholderType == _PlaceholderType.progress
        ? _loadingBuilder
        : null;
  }

  ImageErrorWidgetBuilder? errorWidgetBuilder() {
    return errorBuilder != null ? _errorBuilder : null;
  }

  Widget build(BuildContext context) {
    return Image(
      key: ValueKey(image),
      image: image,
      loadingBuilder: imageLoadingBuilder(),
      frameBuilder: imageFrameBuilder(),
      errorBuilder: errorWidgetBuilder(),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      repeat: repeat,
      color: color,
      colorBlendMode: colorBlendMode,
      matchTextDirection: matchTextDirection,
      filterQuality: filterQuality,
    );
  }

  Widget _stack(Widget revealing, Widget disappearing) {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        FadeWidget(
          child: revealing,
          duration: fadeInDuration,
          curve: fadeInCurve,
        ),
        FadeWidget(
          child: disappearing,
          duration: fadeOutDuration,
          curve: fadeOutCurve,
          direction: AnimationDirection.reverse,
        )
      ],
    );
  }

  Widget _imageBuilder(BuildContext context, Widget child, int? frame,
      bool wasSynchronouslyLoaded) {
    if (frame == null) {
      return child;
    }
    return _image(context, child);
  }

  Widget _placeholderBuilder(BuildContext context, Widget child, int? frame,
      bool wasSynchronouslyLoaded) {
    if (frame == null) {
      if (placeholderFadeInDuration != Duration.zero) {
        return FadeWidget(
          child: _placeholder(context),
          duration: placeholderFadeInDuration,
          curve: fadeInCurve,
        );
      } else {
        return _placeholder(context);
      }
    }
    if (wasSynchronouslyLoaded && !alwaysShowPlaceHolder) {
      return _image(context, child);
    }
    return _stack(
      _image(context, child),
      _placeholder(context),
    );
  }

  bool _wasSynchronouslyLoaded = false;
  bool _isLoaded = false;

  Widget _preLoadingBuilder(BuildContext context, Widget child, int? frame,
      bool wasSynchronouslyLoaded) {
    _wasSynchronouslyLoaded = wasSynchronouslyLoaded;
    _isLoaded = frame != null;
    return child;
  }

  Widget _loadingBuilder(
      BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (_isLoaded) {
      if (_wasSynchronouslyLoaded) {
        return _image(context, child);
      }
      return _stack(
        _image(context, child),
        _progressIndicator(context, null),
      );
    }

    if (placeholderFadeInDuration != Duration.zero) {
      return FadeWidget(
        child: _progressIndicator(context, loadingProgress),
        duration: placeholderFadeInDuration,
        curve: fadeInCurve,
      );
    } else {
      return _progressIndicator(context, loadingProgress);
    }
  }

  Widget _image(BuildContext context, Widget child) {
    if (imageBuilder != null) {
      return imageBuilder!(context, child);
    } else {
      return child;
    }
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stacktrace,
  ) {
    if (errorBuilder == null) {
      throw StateError('Try to build errorBuilder with errorBuilder null');
    }
    return errorBuilder!(context, error, stacktrace);
  }

  Widget _progressIndicator(
      BuildContext context, ImageChunkEvent? loadingProgress) {
    if (progressIndicatorBuilder == null) {
      throw StateError(
          'Try to build progressIndicatorBuilder with progressIndicatorBuilder null');
    }
    return progressIndicatorBuilder!(context, loadingProgress);
  }

  Widget _placeholder(BuildContext context) {
    if (placeholderBuilder != null) {
      return placeholderBuilder!(context);
    }
    return Container();
  }

  _PlaceholderType _definePlaceholderType() {
    assert(placeholderBuilder == null || progressIndicatorBuilder == null);

    if (placeholderBuilder != null) return _PlaceholderType.static;
    if (progressIndicatorBuilder != null) {
      return _PlaceholderType.progress;
    }
    return _PlaceholderType.none;
  }
}
