// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'animated_fade_out_fade_in.dart';
import 'basic.dart';
import 'framework.dart';
import 'image.dart';


// Examples can assume:
// Uint8List bytes;

/// Signature for the [FadeInImage.animationBuilder] callback.
///
/// The `target` is the image that should be (eventually) shown when
/// `isTargetLoaded == true`. `target` maps to [FadeInImage.image]. 
/// 
/// The `placeholder` is the image initially shown when `isTargetLoaded == false`.
/// `placeholder` maps to [FadeInImage.placeholder].
/// 
/// `isTargetLoaded` will initially start as `false` and will transition to
/// `true` when `target` supplies its first frame. It will transition back to
/// `false` only if [FadeInImage.image] is changed to a new [ImageProvider].
///
///
/// {@tool snippet}
///
/// ```dart
/// Widget fadeOutFadeInAnimationBuilder(Widget target, Widget placeholder, bool isTargetLoaded) => 
///   AnimatedFadeOutFadeIn(
///     target: target,
///     placeholder: placeholder,
///     isTargetLoaded: isTargetLoaded,
///     fadeInDuration: const Duration(milliseconds: 300),
///     fadeOutDuration: Curves.easeOut,
///     fadeInCurve: const Duration(milliseconds: 700),
///     fadeOutCurve: Curves.easeIn,
///   );
/// ```
/// {@end-tool}
typedef FadeInImageAnimationBuilder = Widget Function(Widget target, Widget placeholder, bool isTargetLoaded);

/// An image that shows a [placeholder] image while the target [image] is
/// loading, then fades in the new image when it loads. Uses the 
/// [animationBuilder] to fade between images.
///
/// Use this class to display long-loading images, such as [new NetworkImage],
/// so that the image appears on screen with a graceful animation rather than
/// abruptly popping onto the screen.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=pK738Pg9cxc}
///
/// If the [image] emits an [ImageInfo] synchronously, such as when the image
/// has been loaded and cached, the [image] is displayed immediately, and the
/// [placeholder] is never displayed.
///
/// The [fadeOutDuration], [fadeOutCurve], [fadeInDuration] and [fadeInCurve]
/// properties are deprecated in favour of the [animationBuilder].
///
/// The [fadeOutDuration] and [fadeOutCurve] properties control the fade-out
/// animation of the [placeholder].
///
/// The [fadeInDuration] and [fadeInCurve] properties control the fade-in
/// animation of the target [image].
///
/// Prefer a [placeholder] that's already cached so that it is displayed
/// immediately. This prevents it from popping onto the screen.
///
/// When [image] changes, it is resolved to a new [ImageStream]. If the new
/// [ImageStream.key] is different, this widget subscribes to the new stream and
/// replaces the displayed image with images emitted by the new stream.
///
/// When [placeholder] changes and the [image] has not yet emitted an
/// [ImageInfo], then [placeholder] is resolved to a new [ImageStream]. If the
/// new [ImageStream.key] is different, this widget subscribes to the new stream
/// and replaces the displayed image to images emitted by the new stream.
///
/// When either [placeholder] or [image] changes, this widget continues showing
/// the previously loaded image (if any) until the new image provider provides a
/// different image. This is known as "gapless playback" (see also
/// [Image.gaplessPlayback]).
///
/// {@tool snippet}
///
/// ```dart
/// FadeInImage(
///   // here `bytes` is a Uint8List containing the bytes for the in-memory image
///   placeholder: MemoryImage(bytes),
///   image: NetworkImage('https://backend.example.com/image.png'),
///   animationBuilder: (Widget target, Widget placeholder, bool isTargetLoaded) => AnimatedFadeOutFadeIn(
///     target: target,
///     placeholder: placeholder,
///     isTargetLoaded: isTargetLoaded,
///     fadeInDuration: const Duration(milliseconds: 300),
///     fadeOutDuration: Curves.easeOut,
///     fadeInCurve: const Duration(milliseconds: 700),
///     fadeOutCurve: Curves.easeIn,
///   );
/// )
/// ```
/// {@end-tool}
class FadeInImage extends StatelessWidget {
  /// Creates a widget that displays a [placeholder] while an [image] is loading,
  /// then fades from the placeholder to the image using the [animationBuilder].
  ///
  /// The [placeholder] and [image] may be composed in a [ResizeImage] to provide
  /// a custom decode/cache size.
  ///
  /// The [placeholder], [image], [alignment], [repeat], and [matchTextDirection]
  /// arguments must not be null.
  /// 
  /// If the [animationBuilder] argument is null then the [fadeOutDuration],
  /// [fadeOutCurve], [fadeInDuration] and [fadeInCurve] arguments must not be
  /// null.
  ///
  /// If [excludeFromSemantics] is true, then [imageSemanticLabel] will be ignored.
  FadeInImage({
    Key key,
    @required this.placeholder,
    this.placeholderErrorBuilder,
    @required this.image,
    this.imageErrorBuilder,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    @deprecated this.fadeOutDuration = const Duration(milliseconds: 300),
    @deprecated this.fadeOutCurve = Curves.easeOut,
    @deprecated this.fadeInDuration = const Duration(milliseconds: 700),
    @deprecated this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    FadeInImageAnimationBuilder animationBuilder,
  }) : assert(placeholder != null),
       assert(image != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       animationBuilder = animationBuilder ?? _defaultAnimationBuilder(fadeOutDuration, fadeOutCurve, fadeInDuration, fadeInCurve),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in memory while
  /// loading the final image from the network.
  ///
  /// The `placeholder` argument contains the bytes of the in-memory image.
  ///
  /// The `image` argument is the URL of the final image.
  ///
  /// The `placeholderScale` and `imageScale` arguments are passed to their
  /// respective [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// If [placeholderCacheWidth], [placeholderCacheHeight], [imageCacheWidth],
  /// or [imageCacheHeight] are provided, it indicates to the
  /// engine that the respective image should be decoded at the specified size.
  /// The image will be rendered to the constraints of the layout or [width]
  /// and [height] regardless of these parameters. These parameters are primarily
  /// intended to reduce the memory usage of [ImageCache].
  ///
  /// The [placeholder], [image], [placeholderScale], [imageScale],
  /// [alignment], [repeat], and [matchTextDirection] arguments must not be
  /// null.
  /// 
  /// If the [animationBuilder] argument is null then the [fadeOutDuration],
  /// [fadeOutCurve], [fadeInDuration] and [fadeInCurve] arguments must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [new Image.memory], which has more details about loading images from
  ///    memory.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImage.memoryNetwork({
    Key key,
    @required Uint8List placeholder,
    this.placeholderErrorBuilder,
    @required String image,
    this.imageErrorBuilder,
    double placeholderScale = 1.0,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    @deprecated this.fadeOutDuration = const Duration(milliseconds: 300),
    @deprecated this.fadeOutCurve = Curves.easeOut,
    @deprecated this.fadeInDuration = const Duration(milliseconds: 700),
    @deprecated this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    int placeholderCacheWidth,
    int placeholderCacheHeight,
    int imageCacheWidth,
    int imageCacheHeight,
    FadeInImageAnimationBuilder animationBuilder,
  }) : assert(placeholder != null),
       assert(image != null),
       assert(placeholderScale != null),
       assert(imageScale != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       placeholder = ResizeImage.resizeIfNeeded(placeholderCacheWidth, placeholderCacheHeight, MemoryImage(placeholder, scale: placeholderScale)),
       image = ResizeImage.resizeIfNeeded(imageCacheWidth, imageCacheHeight, NetworkImage(image, scale: imageScale)),
       animationBuilder = animationBuilder ?? _defaultAnimationBuilder(fadeOutDuration, fadeOutCurve, fadeInDuration, fadeInCurve),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in an asset bundle
  /// while loading the final image from the network.
  ///
  /// The `placeholder` argument is the key of the image in the asset bundle.
  ///
  /// The `image` argument is the URL of the final image.
  ///
  /// The `placeholderScale` and `imageScale` arguments are passed to their
  /// respective [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// If `placeholderScale` is omitted or is null, pixel-density-aware asset
  /// resolution will be attempted for the [placeholder] image. Otherwise, the
  /// exact asset specified will be used.
  ///
  /// If [placeholderCacheWidth], [placeholderCacheHeight], [imageCacheWidth],
  /// or [imageCacheHeight] are provided, it indicates to the
  /// engine that the respective image should be decoded at the specified size.
  /// The image will be rendered to the constraints of the layout or [width]
  /// and [height] regardless of these parameters. These parameters are primarily
  /// intended to reduce the memory usage of [ImageCache].
  ///
  /// The [placeholder], [image], [imageScale], [fadeOutDuration], [alignment],
  /// [repeat] and [matchTextDirection] arguments must not be null.
  /// 
  /// If the [animationBuilder] argument is null then the [fadeOutDuration],
  /// [fadeOutCurve], [fadeInDuration] and [fadeInCurve] arguments must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [new Image.asset], which has more details about loading images from
  ///    asset bundles.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImage.assetNetwork({
    Key key,
    @required String placeholder,
    this.placeholderErrorBuilder,
    @required String image,
    this.imageErrorBuilder,
    AssetBundle bundle,
    double placeholderScale,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    @deprecated this.fadeOutDuration = const Duration(milliseconds: 300),
    @deprecated this.fadeOutCurve = Curves.easeOut,
    @deprecated this.fadeInDuration = const Duration(milliseconds: 700),
    @deprecated this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    int placeholderCacheWidth,
    int placeholderCacheHeight,
    int imageCacheWidth,
    int imageCacheHeight,
    FadeInImageAnimationBuilder animationBuilder,
  }) : assert(placeholder != null),
       assert(image != null),
       placeholder = placeholderScale != null
         ? ResizeImage.resizeIfNeeded(placeholderCacheWidth, placeholderCacheHeight, ExactAssetImage(placeholder, bundle: bundle, scale: placeholderScale))
         : ResizeImage.resizeIfNeeded(placeholderCacheWidth, placeholderCacheHeight, AssetImage(placeholder, bundle: bundle)),
       assert(imageScale != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       image = ResizeImage.resizeIfNeeded(imageCacheWidth, imageCacheHeight, NetworkImage(image, scale: imageScale)),
       animationBuilder = animationBuilder ?? _defaultAnimationBuilder(fadeOutDuration, fadeOutCurve, fadeInDuration, fadeInCurve),
       super(key: key);

  /// Image displayed while the target [image] is loading.
  final ImageProvider placeholder;

  /// A builder function that is called if an error occurs during placeholder
  /// image loading.
  ///
  /// If this builder is not provided, any exceptions will be reported to
  /// [FlutterError.onError]. If it is provided, the caller should either handle
  /// the exception by providing a replacement widget, or rethrow the exception.
  final ImageErrorWidgetBuilder placeholderErrorBuilder;

  /// The target image that is displayed once it has loaded.
  final ImageProvider image;

  /// A builder function that is called if an error occurs during image loading.
  ///
  /// If this builder is not provided, any exceptions will be reported to
  /// [FlutterError.onError]. If it is provided, the caller should either handle
  /// the exception by providing a replacement widget, or rethrow the exception.
  final ImageErrorWidgetBuilder imageErrorBuilder;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [image].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [image].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
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
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether to exclude this image from semantics.
  ///
  /// This is useful for images which do not contribute meaningful information
  /// to an application.
  final bool excludeFromSemantics;

  /// A semantic description of the [image].
  ///
  /// Used to provide a description of the [image] to TalkBack on Android, and
  /// VoiceOver on iOS.
  ///
  /// This description will be used both while the [placeholder] is shown and
  /// once the image has loaded.
  final String imageSemanticLabel;

  /// How to build the widget tree containing the [target] and [placeholder] 
  /// given the current loading state of [target].
  /// 
  /// This is expected to be an Animation (like [AnimatedFadeOutFadeIn] or
  /// [AnimatedCrossFade]) but could is not strictly required to be an animation.
  /// 
  /// Defaults to [_defaultAnimationBuilder].
  final FadeInImageAnimationBuilder animationBuilder;

  /// The default animation used to maintain backwards compatibility used during
  /// construction. The parameters passed through the contructor for 
  static FadeInImageAnimationBuilder _defaultAnimationBuilder(
    Duration fadeOutDuration, 
    Curve fadeOutCurve, 
    Duration fadeInDuration, 
    Curve fadeInCurve,
  ){
    assert(fadeOutDuration != null);
    assert(fadeOutCurve != null);
    assert(fadeInDuration != null);
    assert(fadeInCurve != null);
    return (Widget target, Widget placeholder, bool isTargetLoaded) => AnimatedFadeOutFadeIn(
      target: target,
      placeholder: placeholder,
      isTargetLoaded: isTargetLoaded,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
    );
  }

  Image _image({
    @required ImageProvider image,
    ImageErrorWidgetBuilder errorBuilder,
    ImageFrameBuilder frameBuilder,
  }) {
    assert(image != null);
    return Image(
      image: image,
      errorBuilder: errorBuilder,
      frameBuilder: frameBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = _image(
      image: image,
      errorBuilder: imageErrorBuilder,
      frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded)
          return child;
        return animationBuilder(child, _image(image: placeholder, errorBuilder: placeholderErrorBuilder), frame != null);
      },
    );

    if (!excludeFromSemantics) {
      result = Semantics(
        container: imageSemanticLabel != null,
        image: true,
        label: imageSemanticLabel ?? '',
        child: result,
      );
    }

    return result;
  }
}
