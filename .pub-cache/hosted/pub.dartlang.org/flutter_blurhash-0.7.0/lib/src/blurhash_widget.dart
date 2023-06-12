import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

const _DEFAULT_SIZE = 32;

/// Display a Hash then fade to Image
class BlurHash extends StatefulWidget {
  const BlurHash({
    required this.hash,
    Key? key,
    this.color = Colors.blueGrey,
    this.imageFit = BoxFit.fill,
    this.decodingWidth = _DEFAULT_SIZE,
    this.decodingHeight = _DEFAULT_SIZE,
    this.image,
    this.onDecoded,
    this.onDisplayed,
    this.onReady,
    this.onStarted,
    this.duration = const Duration(milliseconds: 1000),
    this.httpHeaders = const {},
    this.curve = Curves.easeOut,
    this.errorBuilder,
  })  : assert(decodingWidth > 0),
        assert(decodingHeight != 0),
        super(key: key);

  /// Callback when hash is decoded
  final VoidCallback? onDecoded;

  /// Callback when hash is decoded
  final VoidCallback? onDisplayed;

  /// Callback when image is downloaded
  final VoidCallback? onReady;

  /// Callback when image is downloaded
  final VoidCallback? onStarted;

  /// Hash to decode
  final String hash;

  /// Displayed background color before decoding
  final Color color;

  /// How to fit decoded & downloaded image
  final BoxFit imageFit;

  /// Decoding definition
  final int decodingWidth;

  /// Decoding definition
  final int decodingHeight;

  /// Remote resource to download
  final String? image;

  final Duration duration;

  final Curve curve;

  /// Http headers for secure call like bearer
  final Map<String, String> httpHeaders;

  /// Network image errorBuilder
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  BlurHashState createState() => BlurHashState();
}

class BlurHashState extends State<BlurHash> {
  late Future<ui.Image> _image;
  late bool loaded;
  late bool loading;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _decodeImage();
    loaded = false;
    loading = false;
  }

  @override
  void didUpdateWidget(BlurHash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hash != oldWidget.hash ||
        widget.image != oldWidget.image ||
        widget.decodingWidth != oldWidget.decodingWidth ||
        widget.decodingHeight != oldWidget.decodingHeight) {
      _init();
    }
  }

  void _decodeImage() {
    _image = blurHashDecodeImage(
      blurHash: widget.hash,
      width: widget.decodingWidth,
      height: widget.decodingHeight,
    );

    _image.whenComplete(() => widget.onDecoded?.call());
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          buildBlurHashBackground(),
          if (widget.image != null) prepareDisplayedImage(widget.image!),
        ],
      );

  Widget prepareDisplayedImage(String image) => Image.network(
        image,
        fit: widget.imageFit,
        headers: widget.httpHeaders,
        errorBuilder: widget.errorBuilder,
        loadingBuilder: (context, img, loadingProgress) {
          // Download started
          if (loading == false) {
            loading = true;
            widget.onStarted?.call();
          }

          if (loadingProgress == null) {
            // Image is now loaded, trigger the event
            loaded = true;
            widget.onReady?.call();
            return _DisplayImage(
              child: img,
              duration: widget.duration,
              curve: widget.curve,
              onCompleted: () => widget.onDisplayed?.call(),
            );
          } else {
            return const SizedBox();
          }
        },
      );

  /// Decode the blurhash then display the resulting Image
  Widget buildBlurHashBackground() => FutureBuilder<ui.Image>(
        future: _image,
        builder: (ctx, snap) =>
            snap.hasData ? Image(image: UiImage(snap.data!), fit: widget.imageFit) : Container(color: widget.color),
      );
}

// Inner display details & controls
class _DisplayImage extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback onCompleted;

  const _DisplayImage({
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    required this.curve,
    required this.onCompleted,
    Key? key,
  }) : super(key: key);

  @override
  _DisplayImageState createState() => _DisplayImageState();
}

class _DisplayImageState extends State<_DisplayImage> with SingleTickerProviderStateMixin {
  late Animation<double> opacity;
  late AnimationController controller;

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: opacity,
        child: widget.child,
      );

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: widget.duration, vsync: this);
    final curved = CurvedAnimation(parent: controller, curve: widget.curve);
    opacity = Tween<double>(begin: .0, end: 1.0).animate(curved);
    controller.forward();

    curved.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted.call();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class UiImage extends ImageProvider<UiImage> {
  final ui.Image image;
  final double scale;

  const UiImage(this.image, {this.scale = 1.0});

  @override
  Future<UiImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<UiImage>(this);

  @override
  ImageStreamCompleter load(UiImage key, DecoderCallback decode) => OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(UiImage key) async {
    assert(key == this);
    return ImageInfo(image: image, scale: key.scale);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final UiImage typedOther = other;
    return image == typedOther.image && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(image.hashCode, scale);

  @override
  String toString() => '$runtimeType(${describeIdentity(image)}, scale: $scale)';
}
