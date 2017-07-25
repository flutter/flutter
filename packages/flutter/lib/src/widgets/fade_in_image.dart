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

/// An image that shows a [placeholder] image while the target [image] is
/// loading, then fades in the new image when it loads.
///
/// Use this class to display long-loading images, such as [new Image.network],
/// so that the image appears on screen with a graceful animation rather than a
/// sudden jerk.
///
/// This image ignores the [placeholder]'s and [image]'s `color` and `blendMode`
/// properties in order to efficiently perform the cross-fade animation.
///
/// If the [image]'s [ImageProvider] returns [ImageInfo] synchronously, such as
/// when the image has been loaded and cached, the [image] is displayed
/// immediately and the [placeholder] is never displayed.
///
/// [fadeOutDuration] and [fadeOutCurve] control the fade-out animation of the
/// placeholder.
///
/// [fadeInDuration] and [fadeInCurve] control the fade-in animation of the
/// target [image].
///
/// Prefer [placeholder] that's already cached so that it is displayed in one
/// frame. This prevents it from appearing suddenly on the screen.
///
/// ## Sample code:
///
/// ```dart
/// return new FadeInImage(
///   placeholder: new Image.memory(bytes),
///   image: new Image.network('https://yourbackend.com/image.png'),
/// );
/// ```
class FadeInImage extends StatefulWidget {
  /// Creates a widget that displays a [placeholder] while an [image] is loading
  /// then cross-fades to display the [image].
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration] and [fadeInCurve] arguments must not be null.
  const FadeInImage({
    Key key,
    @required this.placeholder,
    @required this.image,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
  }) : assert(placeholder != null),
       assert(image != null),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in-memory while
  /// loading the final image from the network.
  ///
  /// [placeholder] contains the bytes of the in-memory image.
  ///
  /// [image] is the URL of the final image.
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration] and [fadeInCurve] arguments must not be null.
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
    double scale: 1.0,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
  }) : assert(placeholder != null),
      assert(image != null),
      placeholder = new MemoryImage(placeholder, scale: scale),
      image = new NetworkImage(image, scale: scale),
      assert(fadeOutDuration != null),
      assert(fadeOutCurve != null),
      assert(fadeInDuration != null),
      assert(fadeInCurve != null),
      super(key: key);

  /// Creates a widget that uses a placeholder image stored in an asset bundle
  /// while loading the final image from the network.
  ///
  /// [placeholder] is the key of the image in the asset bundle.
  ///
  /// [image] is the URL of the final image.
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration] and [fadeInCurve] arguments must not be null.
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
    double scale: 1.0,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
  }) : assert(placeholder != null),
       assert(image != null),
       placeholder = scale != null
         ? new ExactAssetImage(placeholder, bundle: bundle, scale: scale)
         : new AssetImage(placeholder, bundle: bundle),
       image = new NetworkImage(image, scale: scale),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
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
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

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

  @override
  State<StatefulWidget> createState() => new _FadeInImageState();
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
        size: widget.width != null && widget.height != null ? new Size(widget.width, widget.height) : null
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

  void dispose() {
    assert(_imageStream != null);
    _imageStream.removeListener(_handleImageChanged);
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
    _imageResolver = new _ImageProviderResolver(state: this, listener: _updatePhase);
    _placeholderResolver = new _ImageProviderResolver(state: this, listener: () {
      setState(() {
        // Trigger rebuild to display the placeholder image
      });
    });
    _controller = new AnimationController(
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
    if (widget.image != oldWidget.image)
      _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageResolver.resolve(widget.image);
    _placeholderResolver.resolve(widget.placeholder);

    if (_phase == FadeInImagePhase.start)
      _updatePhase();
  }

  void _updatePhase() {
    setState(() {
      switch(_phase) {
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
            _animation = new CurvedAnimation(
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
            _animation = new CurvedAnimation(
              parent: _controller,
              curve: widget.fadeInCurve,
            );
            _phase = FadeInImagePhase.fadeIn;
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
    _imageResolver.dispose();
    _placeholderResolver.dispose();
    _controller.dispose();
    super.dispose();
  }

  ImageInfo get _imageInfo {
    switch(_phase) {
      case FadeInImagePhase.start:
      case FadeInImagePhase.waiting:
      case FadeInImagePhase.fadeOut:
        return _placeholderResolver._imageInfo;
      case FadeInImagePhase.fadeIn:
      case FadeInImagePhase.completed:
        return _imageResolver._imageInfo;
    }

    throw new StateError('Unrecognized FadeInImage phase: $_phase');
  }

  @override
  Widget build(BuildContext context) {
    assert(_phase != FadeInImagePhase.start);
    return new RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: new Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('phase: $_phase');
    description.add('pixels: $_imageInfo');
    description.add('image stream: ${_imageResolver._imageStream}');
    description.add('placeholder stream: ${_placeholderResolver._imageStream}');
  }
}
