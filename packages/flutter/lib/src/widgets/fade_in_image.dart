// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';
import 'ticker_provider.dart';

// Examples can assume:
// Uint8List bytes;

/// An image that shows a [placeholder] image while the target [image] is
/// loading, then fades in the new image when it loads.
///
/// Use this class to display long-loading images, such as [new NetworkImage],
/// so that the image appears on screen with a graceful animation rather than
/// abruptly pops onto the screen.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=pK738Pg9cxc}
///
/// If the [image] emits an [ImageInfo] synchronously, such as when the image
/// has been loaded and cached, the [image] is displayed immediately and the
/// [placeholder] is never displayed.
///
/// [fadeOutDuration] and [fadeOutCurve] control the fade-out animation of the
/// placeholder.
///
/// [fadeInDuration] and [fadeInCurve] control the fade-in animation of the
/// target [image].
///
/// Prefer a [placeholder] that's already cached so that it is displayed in one
/// frame. This prevents it from popping onto the screen.
///
/// When [image] changes it is resolved to a new [ImageStream]. If the new
/// [ImageStream.key] is different this widget subscribes to the new stream and
/// replaces the displayed image with images emitted by the new stream.
///
/// When [placeholder] changes and the [image] has not yet emitted an
/// [ImageInfo], then [placeholder] is resolved to a new [ImageStream]. If the
/// new [ImageStream.key] is different this widget subscribes to the new stream
/// and replaces the displayed image to images emitted by the new stream.
///
/// When either [placeholder] or [image] changes, this widget continues showing
/// the previously loaded image (if any) until the new image provider provides a
/// different image. This is known as "gapless playback" (see also
/// [Image.gaplessPlayback]).
///
/// {@tool sample}
///
/// ```dart
/// FadeInImage(
///   // here `bytes` is a Uint8List containing the bytes for the in-memory image
///   placeholder: MemoryImage(bytes),
///   image: NetworkImage('https://backend.example.com/image.png'),
/// )
/// ```
/// {@end-tool}
class FadeInImage extends StatefulWidget {
  /// Creates a widget that displays a [placeholder] while an [image] is loading
  /// then cross-fades to display the [image].
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration], [fadeInCurve], [alignment], [repeat], and
  /// [matchTextDirection] arguments must not be null.
  ///
  /// There are two different semantic label for the class.
  /// [placeholderSemanticLabel] is used for defining a semantics label for
  /// [placeholder]. [imageSemanticLabel] is used for defining a semantics label
  /// for [image]
  ///
  /// If [excludeFromSemantics] is true, then [placeholderSemanticLabel] and
  /// [imageSemanticLabel] will be ignored.
  const FadeInImage({
    Key key,
    @required this.placeholder,
    @required this.image,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.placeholderSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : assert(placeholder != null),
       assert(image != null),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in memory while
  /// loading the final image from the network.
  ///
  /// [placeholder] contains the bytes of the in-memory image.
  ///
  /// [image] is the URL of the final image.
  ///
  /// [placeholderScale] and [imageScale] are passed to their respective
  /// [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// The [placeholder], [image], [placeholderScale], [imageScale],
  /// [fadeOutDuration], [fadeOutCurve], [fadeInDuration], [fadeInCurve],
  /// [alignment], [repeat], and [matchTextDirection] arguments must not be
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
    @required String image,
    double placeholderScale = 1.0,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.placeholderSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : assert(placeholder != null),
       assert(image != null),
       assert(placeholderScale != null),
       assert(imageScale != null),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       placeholder = MemoryImage(placeholder, scale: placeholderScale),
       image = NetworkImage(image, scale: imageScale),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in an asset bundle
  /// while loading the final image from the network.
  ///
  /// [placeholder] is the key of the image in the asset bundle.
  ///
  /// [image] is the URL of the final image.
  ///
  /// [placeholderScale] and [imageScale] are passed to their respective
  /// [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// If [placeholderScale] is omitted or is null, the pixel-density-aware asset
  /// resolution will be attempted for the [placeholder] image. Otherwise, the
  /// exact asset specified will be used.
  ///
  /// The [placeholder], [image], [imageScale], [fadeOutDuration],
  /// [fadeOutCurve], [fadeInDuration], [fadeInCurve], [alignment], [repeat],
  /// and [matchTextDirection] arguments must not be null.
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
    @required String image,
    AssetBundle bundle,
    double placeholderScale,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.placeholderSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : assert(placeholder != null),
       assert(image != null),
       placeholder = placeholderScale != null
         ? ExactAssetImage(placeholder, bundle: bundle, scale: placeholderScale)
         : AssetImage(placeholder, bundle: bundle),
       assert(imageScale != null),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       image = NetworkImage(image, scale: imageScale),
       super(key: key);

  /// Image displayed while the target [image] is loading.
  final ImageProvider placeholder;

  /// The target image that is displayed.
  final ImageProvider image;

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
  /// Useful for images which do not contribute meaningful information to an
  /// application.
  final bool excludeFromSemantics;

  /// A Semantic description of the [placeholder].
  ///
  /// Used to provide a description of the [placeholder] to TalkBack on Android, and
  /// VoiceOver on iOS.
  final String placeholderSemanticLabel;

  /// A Semantic description of the [image].
  ///
  /// Used to provide a description of the [image] to TalkBack on Android, and
  /// VoiceOver on iOS.
  final String imageSemanticLabel;

  @override
  State<StatefulWidget> createState() => _FadeInImageState();
}


/// The phases a [FadeInImage] goes through.
@visibleForTesting
enum FadeInImagePhase {
  /// The initial state.
  ///
  /// We do not yet know whether the target image is ready and therefore no
  /// animation is necessary, or whether we need to use the placeholder and
  /// wait for the image to load.
  start,

  /// Waiting for the target image to load.
  waiting,

  /// Fading out previous image.
  fadeOut,

  /// Fading in new image.
  fadeIn,

  /// Fade-in complete.
  completed,
}

typedef _ImageProviderResolverListener = void Function();

class _ImageProviderResolver {
  _ImageProviderResolver({
    @required this.state,
    @required this.listener,
  });

  final _FadeInImageState state;
  final _ImageProviderResolverListener listener;

  FadeInImage get widget => state.widget;

  ImageStream _imageStream;
  ImageInfo _imageInfo;

  void resolve(ImageProvider provider) {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = provider.resolve(createLocalImageConfiguration(
      state.context,
      size: widget.width != null && widget.height != null ? Size(widget.width, widget.height) : null,
    ));
    assert(_imageStream != null);

    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      _imageStream.addListener(_handleImageChanged);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo = imageInfo;
    listener();
  }

  void stopListening() {
    _imageStream?.removeListener(_handleImageChanged);
  }
}

class _FadeInImageState extends State<FadeInImage> with TickerProviderStateMixin {
  _ImageProviderResolver _imageResolver;
  _ImageProviderResolver _placeholderResolver;

  AnimationController _controller;
  Animation<double> _animation;

  FadeInImagePhase _phase = FadeInImagePhase.start;
  FadeInImagePhase get phase => _phase;

  @override
  void initState() {
    _imageResolver = _ImageProviderResolver(state: this, listener: _updatePhase);
    _placeholderResolver = _ImageProviderResolver(state: this, listener: () {
      setState(() {
        // Trigger rebuild to display the placeholder image
      });
    });
    _controller = AnimationController(
      value: 1.0,
      vsync: this,
    );
    _controller.addListener(() {
      setState(() {
        // Trigger rebuild to update opacity value.
      });
    });
    _controller.addStatusListener((AnimationStatus status) {
      _updatePhase();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FadeInImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image || widget.placeholder != oldWidget.placeholder)
      _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageResolver.resolve(widget.image);

    // No need to resolve the placeholder if we are past the placeholder stage.
    if (_isShowingPlaceholder)
      _placeholderResolver.resolve(widget.placeholder);

    if (_phase == FadeInImagePhase.start)
      _updatePhase();
  }

  void _updatePhase() {
    setState(() {
      switch (_phase) {
        case FadeInImagePhase.start:
          if (_imageResolver._imageInfo != null)
            _phase = FadeInImagePhase.completed;
          else
            _phase = FadeInImagePhase.waiting;
          break;
        case FadeInImagePhase.waiting:
          if (_imageResolver._imageInfo != null) {
            // Received image data. Begin placeholder fade-out.
            _controller.duration = widget.fadeOutDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.fadeOutCurve,
            );
            _phase = FadeInImagePhase.fadeOut;
            _controller.reverse(from: 1.0);
          }
          break;
        case FadeInImagePhase.fadeOut:
          if (_controller.status == AnimationStatus.dismissed) {
            // Done fading out placeholder. Begin target image fade-in.
            _controller.duration = widget.fadeInDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.fadeInCurve,
            );
            _phase = FadeInImagePhase.fadeIn;
            _placeholderResolver.stopListening();
            _controller.forward(from: 0.0);
          }
          break;
        case FadeInImagePhase.fadeIn:
          if (_controller.status == AnimationStatus.completed) {
            // Done finding in new image.
            _phase = FadeInImagePhase.completed;
          }
          break;
        case FadeInImagePhase.completed:
          // Nothing to do.
          break;
      }
    });
  }

  @override
  void dispose() {
    _imageResolver.stopListening();
    _placeholderResolver.stopListening();
    _controller.dispose();
    super.dispose();
  }

  bool get _isShowingPlaceholder {
    assert(_phase != null);
    switch (_phase) {
      case FadeInImagePhase.start:
      case FadeInImagePhase.waiting:
      case FadeInImagePhase.fadeOut:
        return true;
      case FadeInImagePhase.fadeIn:
      case FadeInImagePhase.completed:
        return false;
    }

    return null;
  }

  ImageInfo get _imageInfo {
    return _isShowingPlaceholder
      ? _placeholderResolver._imageInfo
      : _imageResolver._imageInfo;
  }

  String get _semanticLabel {
    return _isShowingPlaceholder
      ? widget.placeholderSemanticLabel
      : widget.imageSemanticLabel;
  }

  @override
  Widget build(BuildContext context) {
    assert(_phase != FadeInImagePhase.start);
    final ImageInfo imageInfo = _imageInfo;
    final RawImage image = RawImage(
      image: imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: imageInfo?.scale ?? 1.0,
      color: Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
    );

    if (widget.excludeFromSemantics) {
      return image;
    }

    return Semantics(
      container: _semanticLabel != null,
      image: true,
      label: _semanticLabel == null ? '' : _semanticLabel,
      child: image,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(EnumProperty<FadeInImagePhase>('phase', _phase));
    description.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
    description.add(DiagnosticsProperty<ImageStream>('image stream', _imageResolver._imageStream));
    description.add(DiagnosticsProperty<ImageStream>('placeholder stream', _placeholderResolver._imageStream));
  }
}
