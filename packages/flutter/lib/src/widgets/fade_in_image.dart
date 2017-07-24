// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
/// Example:
///
/// ```dart
/// return new FadeInImage(
///   placeholder: new Image.memory(bytes),
///   image: new Image.network('https://yourbackend.com/image.png'),
/// );
/// ```
///
/// Prefer [placeholder] that's already cached so that it can be displayed in
/// the frame in which the [FadeInImage] is built.
class FadeInImage extends StatefulWidget {
  const FadeInImage({
    Key key,
    @required this.placeholder,
    @required this.image,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
  }) : super(key: key);

  /// Image displayed while the target [image] is loading.
  final Image placeholder;

  /// The target image that is displayed.
  final Image image;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [image].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [image].
  final Curve fadeInCurve;

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


class _FadeInImageState extends State<FadeInImage> with TickerProviderStateMixin {
  ImageStream _imageStream;
  ImageInfo _imageInfo;
  AnimationController _controller;
  Animation<double> _animation;

  FadeInImagePhase _phase = FadeInImagePhase.start;
  FadeInImagePhase get phase => _phase;

  @override
  void initState() {
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
    if (widget.image.image != oldWidget.image.image)
      _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    final ImageStream oldImageStream = _imageStream;
    final Image image = widget.image;
    _imageStream = image.image.resolve(createLocalImageConfiguration(
        context,
        size: image.width != null && image.height != null ? new Size(image.width, image.height) : null
    ));
    assert(_imageStream != null);

    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      if (!image.gaplessPlayback)
        setState(() { _imageInfo = null; });
      _imageStream.addListener(_handleImageChanged);
    }

    if (_phase == FadeInImagePhase.start)
      _updatePhase();
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
      _updatePhase();
    });
  }

  void _updatePhase() {
    switch(_phase) {
      case FadeInImagePhase.start:
        if (_imageInfo != null)
          _phase = FadeInImagePhase.completed;
        else
          _phase = FadeInImagePhase.waiting;
        break;
      case FadeInImagePhase.waiting:
        if (_imageInfo != null) {
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
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    _imageStream.removeListener(_handleImageChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(_phase != FadeInImagePhase.start);
    if (_phase == FadeInImagePhase.waiting || _phase == FadeInImagePhase.fadeOut)
      return _buildPlaceholderImage();
    else
      return _buildTargetImage();
  }

  Image _buildPlaceholderImage() {
    return new Image(
      key: widget.placeholder.key,
      image: widget.placeholder.image,
      width: widget.placeholder.width,
      height: widget.placeholder.height,
      color: new Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.placeholder.fit,
      alignment: widget.placeholder.alignment,
      repeat: widget.placeholder.repeat,
      centerSlice: widget.placeholder.centerSlice,
      gaplessPlayback: widget.placeholder.gaplessPlayback,
    );
  }

  RawImage _buildTargetImage() {
    final Image image = widget.image;
    return new RawImage(
      image: _imageInfo?.image,
      width: image.width,
      height: image.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: new Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: image.fit,
      alignment: image.alignment,
      repeat: image.repeat,
      centerSlice: image.centerSlice,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('stream: $_imageStream');
    description.add('pixels: $_imageInfo');
  }
}
